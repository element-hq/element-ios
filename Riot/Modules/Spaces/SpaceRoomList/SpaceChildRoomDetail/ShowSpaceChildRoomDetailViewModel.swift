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

final class ShowSpaceChildRoomDetailViewModel: ShowSpaceChildRoomDetailViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let childInfo: MXSpaceChildInfo
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    weak var viewDelegate: ShowSpaceChildRoomDetailViewModelViewDelegate?
    weak var coordinatorDelegate: ShowSpaceChildRoomDetailViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, childInfo: MXSpaceChildInfo) {
        self.session = session
        self.childInfo = childInfo
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ShowSpaceChildRoomDetailViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            self.update(viewState: .loading)
            self.session.joinRoom(self.childInfo.childRoomId) { [weak self] (response) in
                guard let self = self else { return }
                switch response {
                case .success:
                    self.loadData()
                    self.coordinatorDelegate?.showSpaceChildRoomDetailViewModelDidComplete(self)
                case .failure(let error):
                    self.update(viewState: .error(error))
                }
            }
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.showSpaceChildRoomDetailViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let avatarViewData = AvatarViewData(avatarUrl: self.childInfo.avatarUrl, mediaManager: self.session.mediaManager, fallbackImage: .matrixItem(self.childInfo.childRoomId, self.childInfo.name))
        self.update(viewState: .loaded(self.childInfo, avatarViewData))
    }
    
    private func update(viewState: ShowSpaceChildRoomDetailViewState) {
        self.viewDelegate?.showSpaceChildRoomDetailViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
