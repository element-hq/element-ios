// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
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

final class ShowSpaceExploreRoomViewModel: ShowSpaceExploreRoomViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let spaceId: String

    private var currentOperation: MXHTTPOperation?
    
    private var itemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            self.updateFilteredItemList()
        }
    }
    private var searchKeyword: String? = nil {
        didSet {
            self.updateFilteredItemList()
        }
    }
    private var filteredItemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            self.update(viewState: .loaded(self.filteredItemDataList))
        }
    }
    
    // MARK: Public

    weak var viewDelegate: ShowSpaceExploreRoomViewModelViewDelegate?
    weak var coordinatorDelegate: ShowSpaceExploreRoomViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ShowSpaceExploreRoomViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            self.coordinatorDelegate?.showSpaceExploreRoomViewModel(self)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.showSpaceExploreRoomViewModelDidCancel(self)
        case .searchChanged(let newText):
            self.searchKeyword = newText
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard let space = session.spaceService.getSpace(withId: self.spaceId) else {
            MXLog.error("[ShowSpaceExploreRoomViewModel] loadData : space with id \(self.spaceId) not found")
            return
        }
        
        self.update(viewState: .spaceFound(space))

        self.update(viewState: .loading)
        
        self.currentOperation = self.session.spaceService.getSpaceChildrenForSpace(withId: self.spaceId, suggestedOnly: false, limit: nil, completion: { [weak self] response in
            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let spaceSummary):
                self.itemDataList = spaceSummary.childInfos.map({ childInfo in
                    let avatarViewData = AvatarViewData(avatarUrl: childInfo.avatarUrl, mediaManager: self.session.mediaManager, fallbackImage: .matrixItem(childInfo.childRoomId, childInfo.name))
                    return SpaceExploreRoomListItemViewData(childInfo: childInfo, avatarViewData: avatarViewData)
                })
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        })
    }
    
    private func update(viewState: ShowSpaceExploreRoomViewState) {
        self.viewDelegate?.showSpaceExploreRoomViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
    
    private func updateFilteredItemList() {
        guard let searchKeyword = self.searchKeyword?.lowercased(), !searchKeyword.isEmpty else {
            self.filteredItemDataList = self.itemDataList
            return
        }
        
        self.filteredItemDataList = self.itemDataList.filter({ itemData in
            return (itemData.childInfo.name?.lowercased().contains(searchKeyword) ?? false) || (itemData.childInfo.topic?.lowercased().contains(searchKeyword) ?? false)
        })
    }
}
