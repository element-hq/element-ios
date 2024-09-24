// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SpaceMemberDetailViewModel: NSObject, SpaceMemberDetailViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let userSessionsService: UserSessionsService
    private let session: MXSession
    private let member: MXRoomMember
    private let spaceId: String
    private var space: MXSpace?
    private(set) var showCancelMenuItem: Bool
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: SpaceMemberDetailViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceMemberDetailViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(userSessionsService: UserSessionsService, session: MXSession, member: MXRoomMember, spaceId: String, showCancelMenuItem: Bool) {
        self.userSessionsService = userSessionsService
        self.session = session
        self.member = member
        self.spaceId = spaceId
        self.showCancelMenuItem = showCancelMenuItem
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceMemberDetailViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .openRoom(let roomId):
            Analytics.shared.viewRoomTrigger = .spaceMemberDetail
            self.coordinatorDelegate?.spaceMemberDetailViewModel(self, showRoomWithId: roomId)
        case .createRoom(let memberId):
            self.createDirectRoom(forMemberWithId: memberId)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.spaceMemberDetailViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.space = self.session.spaceService.getSpace(withId: self.spaceId)
        self.update(viewState: .loaded(self.member, self.space?.room))
    }
    
    private func update(viewState: SpaceMemberDetailViewState) {
        self.viewDelegate?.spaceMemberDetailViewModel(self, didUpdateViewState: viewState)
    }
    
    private func createDirectRoom(forMemberWithId memberId: String) {
        self.update(viewState: .loading)
        guard let account = self.userSessionsService.mainUserSession?.account, let session = account.mxSession else {
            self.update(viewState: .loaded(self.member, self.space?.room))
            return
        }
        
        let invite: [String]? = (session.myUserId != memberId) ? [memberId] : nil
        self.currentOperation = session.vc_canEnableE2EByDefaultInNewRoom(withUsers: invite) { canEnableE2E in
            self.currentOperation = nil
            let roomCreationParameters = MXRoomCreationParameters()
            roomCreationParameters.visibility = kMXRoomDirectoryVisibilityPrivate
            roomCreationParameters.inviteArray = invite
            roomCreationParameters.isDirect = !(invite?.isEmpty ?? true)
            roomCreationParameters.preset = kMXRoomPresetTrustedPrivateChat
            
            if canEnableE2E {
                roomCreationParameters.initialStateEvents = [MXRoomCreationParameters.initialStateEventForEncryption(withAlgorithm: kMXCryptoMegolmAlgorithm)]
            }
            
            self.currentOperation = session.createRoom(parameters: roomCreationParameters) { response in
                self.currentOperation = nil
                self.update(viewState: .loaded(self.member, self.space?.room))
                guard response.isSuccess, let room = response.value else {
                    if let error = response.error {
                        self.update(viewState: .error(error))
                    }
                    return
                }
                Analytics.shared.viewRoomTrigger = .created
                self.coordinatorDelegate?.spaceMemberDetailViewModel(self, showRoomWithId: room.roomId)
            }
        } failure: { error in
            self.update(viewState: .loaded(self.member, self.space?.room))
            if let error = error {
                self.update(viewState: .error(error))
            }
        }
    }

    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
