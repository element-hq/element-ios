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

final class SpaceExploreRoomViewModel: SpaceExploreRoomViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let spaceId: String
    private let spaceName: String?

    private var currentOperation: MXHTTPOperation?
    private var nextBatch: String?
    private var rootSpaceChildInfo: MXSpaceChildInfo?
    
    private var itemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            self.updateFilteredItemList()
        }
    }
    private var searchKeyword: String? {
        didSet {
            self.updateFilteredItemList()
        }
    }
    private var filteredItemDataList: [SpaceExploreRoomListItemViewData] = [] {
        didSet {
            if self.filteredItemDataList.isEmpty {
                if self.itemDataList.isEmpty {
                    self.update(viewState: .emptySpace)
                } else {
                    self.update(viewState: .emptyFilterResult)
                }
            } else {
                self.update(viewState: .loaded(self.filteredItemDataList, self.nextBatch != nil && (self.searchKeyword ?? "").isEmpty))
            }
        }
    }
    
    // MARK: Public

    weak var viewDelegate: SpaceExploreRoomViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceExploreRoomViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceExploreRoomCoordinatorParameters) {
        self.session = parameters.session
        self.spaceId = parameters.spaceId
        self.spaceName = parameters.spaceName
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceExploreRoomViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete(let selectedItem, let sourceView):
            self.coordinatorDelegate?.spaceExploreRoomViewModel(self, didSelect: selectedItem, from: sourceView)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.spaceExploreRoomViewModelDidCancel(self)
        case .searchChanged(let newText):
            self.searchKeyword = newText
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard self.currentOperation == nil else {
            return
        }
        
        if let spaceName = self.spaceName {
            self.update(viewState: .spaceNameFound(spaceName))
        }

        if self.nextBatch == nil {
            self.update(viewState: .loading)
        }
        
        self.currentOperation = self.session.spaceService.getSpaceChildrenForSpace(withId: self.spaceId, suggestedOnly: false, limit: nil, maxDepth: 1, paginationToken: self.nextBatch, completion: { [weak self] response in
            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let spaceSummary):
                self.nextBatch = spaceSummary.nextBatch
                // The MXSpaceChildInfo of the root space is available only in the first batch
                if let rootSpaceInfo = spaceSummary.spaceInfo {
                    self.rootSpaceChildInfo = rootSpaceInfo
                }
                
                let batchedItemDataList: [SpaceExploreRoomListItemViewData] = spaceSummary.childInfos.compactMap({ childInfo in
                    guard let rootSpaceInfo = self.rootSpaceChildInfo, rootSpaceInfo.childrenIds.contains(childInfo.childRoomId) else {
                        return nil
                    }
                    
                    let avatarViewData = AvatarViewData(matrixItemId: childInfo.childRoomId,
                                                        displayName: childInfo.displayName,
                                                        avatarUrl: childInfo.avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        fallbackImage: .matrixItem(childInfo.childRoomId, childInfo.name))
                    return SpaceExploreRoomListItemViewData(childInfo: childInfo, avatarViewData: avatarViewData)
                }).sorted(by: { item1, item2 in
                    return !item2.childInfo.suggested || item1.childInfo.suggested
                })
                self.itemDataList.append(contentsOf: batchedItemDataList)
            case .failure(let error):
                self.update(viewState: .error(error))
            }
            
            self.currentOperation = nil
        })
    }
    
    private func update(viewState: SpaceExploreRoomViewState) {
        self.viewDelegate?.spaceExploreRoomViewModel(self, didUpdateViewState: viewState)
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
