// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

final class SpaceChildRoomDetailViewModel: SpaceChildRoomDetailViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let childInfo: MXSpaceChildInfo
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    private var isRoomJoined: Bool {
        let summary = self.session.room(withRoomId: self.childInfo.childRoomId)?.summary
        return summary?.isJoined ?? false
    }
    
    // MARK: Public

    weak var viewDelegate: SpaceChildRoomDetailViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceChildRoomDetailViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceChildRoomDetailCoordinatorParameters) {
        self.session = parameters.session
        self.childInfo = parameters.childInfo
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceChildRoomDetailViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            if self.isRoomJoined {
                self.coordinatorDelegate?.spaceChildRoomDetailViewModel(self, didOpenRoomWith: self.childInfo.childRoomId)
            } else {
                joinRoom()
            }
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.spaceChildRoomDetailViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let avatarViewData = AvatarViewData(matrixItemId: self.childInfo.childRoomId,
                                            displayName: self.childInfo.displayName,
                                            avatarUrl: self.childInfo.avatarUrl,
                                            mediaManager: self.session.mediaManager,
                                            fallbackImage: .matrixItem(self.childInfo.childRoomId, self.childInfo.name))
        self.update(viewState: .loaded(self.childInfo, avatarViewData, self.isRoomJoined))
    }
    
    private func update(viewState: SpaceChildRoomDetailViewState) {
        self.viewDelegate?.spaceChildRoomDetailViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
    
    private func joinRoom() {
        self.update(viewState: .loading)
        if let canonicalAlias = self.childInfo.canonicalAlias {
            self.session.matrixRestClient.resolveRoomAlias(canonicalAlias) { [weak self] (response) in
                guard let self = self else { return }
                switch response {
                case .success(let resolution):
                    self.joinRoom(withId: resolution.roomId, via: resolution.servers)
                case .failure(let error):
                    MXLog.warning("[SpaceChildRoomDetailViewModel] joinRoom: failed to resolve room alias due to error \(error).")
                    self.joinRoom(withId: self.childInfo.childRoomId, via: nil)
                }
            }
        } else {
            MXLog.warning("[SpaceChildRoomDetailViewModel] joinRoom: no canonical alias provided.")
            joinRoom(withId: self.childInfo.childRoomId, via: nil)
        }
    }
    
    private func joinRoom(withId roomId: String, via viaServers: [String]?) {
        self.session.joinRoom(roomId, viaServers: viaServers, withSignUrl: nil) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success:
                self.loadData()
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
}
