// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SpaceMemberListViewModel: SpaceMemberListViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let spaceId: String
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    var space: MXSpace? {
        return session.spaceService.getSpace(withId: spaceId)
    }
    weak var viewDelegate: SpaceMemberListViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceMemberListViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceMemberListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete(let selectedMember, let sourceView):
            self.coordinatorDelegate?.spaceMemberListViewModel(self, didSelect: selectedMember, from: sourceView)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.spaceMemberListViewModelDidCancel(self)
        case .invite:
            self.coordinatorDelegate?.spaceMemberListViewModelShowInvite(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        if let space = self.session.spaceService.getSpace(withId: spaceId) {
            self.update(viewState: .loaded(space))
        }
    }
    
    private func update(viewState: SpaceMemberListViewState) {
        self.viewDelegate?.spaceMemberListViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
