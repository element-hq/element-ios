// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// View model used by `SpaceDetailViewController`
class SpaceDetailViewModel: SpaceDetailViewModelType {
    
    // MARK: - Properties
    
    weak var coordinatorDelegate: SpaceDetailModelViewModelCoordinatorDelegate?
    weak var viewDelegate: SpaceDetailViewModelViewDelegate?

    private let session: MXSession
    private let spaceId: String
    private let senderId: String?
    private let publicRoom: MXPublicRoom?
    private var spaceGraphObserver: Any?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        self.publicRoom = nil
        self.senderId = nil
    }
    
    init(session: MXSession, publicRoom: MXPublicRoom, senderId: String?) {
        self.session = session
        self.publicRoom = publicRoom
        self.spaceId = publicRoom.roomId
        self.senderId = senderId
    }
    
    deinit {
        if let spaceGraphObserver = spaceGraphObserver {
            NotificationCenter.default.removeObserver(spaceGraphObserver)
        }
    }
    
    // MARK: - Public

    func process(viewAction: SpaceDetailViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .join:
            self.join()
        case .leave:
            self.leave()
        case .open:
            self.coordinatorDelegate?.spaceDetailViewModelDidOpen(self)
        case .dismiss:
            self.coordinatorDelegate?.spaceDetailViewModelDidCancel(self)
        case .dismissed:
            self.coordinatorDelegate?.spaceDetailViewModelDidDismiss(self)
        }
    }
    
    // MARK: - Private
    
    private func update(viewState: SpaceDetailViewState) {
        self.viewDelegate?.spaceDetailViewModel(self, didUpdateViewState: viewState)
    }
    
    private func loadData() {
        if let publicRoom = self.publicRoom {
            let sender: MXUser?
            if let senderId = self.senderId {
                sender = session.user(withUserId: senderId)
            } else {
                sender = nil
            }
            
            self.update(viewState: .loaded(SpaceDetailLoadedParameters(spaceId: publicRoom.roomId,
                                                                       displayName: publicRoom.displayname(),
                                                                       topic: publicRoom.topic,
                                                                       avatarUrl: publicRoom.avatarUrl,
                                                                       joinRule: publicRoom.worldReadable ? .public : .private,
                                                                       membership: self.senderId != nil ? .invite : .unknown,
                                                                       inviterId: self.senderId,
                                                                       inviter: sender,
                                                                       membersCount: UInt(publicRoom.numJoinedMembers))))
        } else {
            guard let space = self.session.spaceService.getSpace(withId: self.spaceId), let summary = space.summary else {
                MXLog.error("[SpaceDetailViewModel] setupViews: no space found")
                return
            }
            
            let parameters = SpaceDetailLoadedParameters(spaceId: space.spaceId,
                                                         displayName: summary.displayname,
                                                         topic: summary.topic,
                                                         avatarUrl: summary.avatar,
                                                         joinRule: nil,
                                                         membership: summary.membership,
                                                         inviterId: nil,
                                                         inviter: nil,
                                                         membersCount: 0)
            self.update(viewState: .loaded(parameters))
            
            self.update(viewState: .loading)
            space.room?.state { state in
                let joinRule = state?.joinRule
                let membersCount = summary.membersCount.joined
                
                var inviterId: String?
                var inviter: MXUser?
                state?.stateEvents.forEach({ event in
                    if event.wireEventType == .roomMember && event.stateKey == self.session.myUserId {
                        guard let userId = event.sender else {
                            return
                        }
                        inviterId = userId
                        inviter = self.session.user(withUserId: userId)
                    }
                })
                
                let parameters = SpaceDetailLoadedParameters(spaceId: space.spaceId,
                                                             displayName: summary.displayname,
                                                             topic: summary.topic,
                                                             avatarUrl: summary.avatar,
                                                             joinRule: joinRule,
                                                             membership: summary.membership,
                                                             inviterId: inviterId,
                                                             inviter: inviter,
                                                             membersCount: membersCount)
                self.update(viewState: .loaded(parameters))
            }
        }
    }
    
    private func join() {
        self.update(viewState: .loading)
        self.session.joinRoom(self.spaceId) { [weak self] (response) in
            guard let self = self else { return }
            switch response {
            case .success:
                self.spaceGraphObserver = NotificationCenter.default.addObserver(forName: MXSpaceService.didBuildSpaceGraph, object: nil, queue: OperationQueue.main) { [weak self] notification in
                    guard let self = self else { return }
                    
                    if let spaceGraphObserver = self.spaceGraphObserver {
                        NotificationCenter.default.removeObserver(spaceGraphObserver)
                    }
                    self.coordinatorDelegate?.spaceDetailViewModelDidJoin(self)
                }
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func leave() {
        self.update(viewState: .loading)
        self.session.leaveRoom(self.spaceId) { [weak self] (response) in
            guard let self = self else { return }
            switch response {
            case .success:
                self.process(viewAction: .dismiss)
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
}
