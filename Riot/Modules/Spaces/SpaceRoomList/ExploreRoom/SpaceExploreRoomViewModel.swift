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
import MatrixSDK

final class SpaceExploreRoomViewModel: SpaceExploreRoomViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let spaceId: String
    private let spaceName: String?

    private var currentOperation: MXHTTPOperation?
    private var nextBatch: String?
    private var rootSpaceChildInfo: MXSpaceChildInfo?
    
    private var spaceRoom: MXRoom?
    private var powerLevels: MXRoomPowerLevels?
    private var powerLevelOfCurrentUser: Int?

    private var canJoin: Bool = false {
        didSet {
            self.update(viewState: .canJoin(self.canJoin))
        }
    }

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
                self.update(viewState: .loaded(self.filteredItemDataList, self.hasMore))
            }
        }
    }
    private var hasMore: Bool {
        self.nextBatch != nil && (self.searchKeyword ?? "").isEmpty
    }
    
    private var spaceGraphObserver: Any?
    var space: MXSpace? {
        return session.spaceService.getSpace(withId: spaceId)
    }
    
    // MARK: Public

    weak var viewDelegate: SpaceExploreRoomViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceExploreRoomViewModelCoordinatorDelegate?
    private(set) var showCancelMenuItem: Bool

    // MARK: - Setup
    
    init(parameters: SpaceExploreRoomCoordinatorParameters) {
        self.session = parameters.session
        self.spaceId = parameters.spaceId
        self.spaceName = parameters.spaceName
        self.showCancelMenuItem = parameters.showCancelMenuItem
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceExploreRoomViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .reloadData:
            self.nextBatch = nil
            self.loadData()
        case .complete(let selectedItem, let sourceView):
            self.coordinatorDelegate?.spaceExploreRoomViewModel(self, didSelect: selectedItem, from: sourceView)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.spaceExploreRoomViewModelDidCancel(self)
        case .searchChanged(let newText):
            self.searchKeyword = newText
        case .addRoom:
            self.coordinatorDelegate?.spaceExploreRoomViewModelDidAddRoom(self)
        case .inviteTo(let item):
            self.coordinatorDelegate?.spaceExploreRoomViewModel(self, inviteTo: item)
        case .revertSuggestion(let item):
            setChild(withRoomId: item.childInfo.childRoomId, suggested: !item.childInfo.suggested)
        case .settings(let item):
            self.coordinatorDelegate?.spaceExploreRoomViewModel(self, openSettingsOf: item)
        case .removeChild(let item):
            removeChild(withRoomId: item.childInfo.childRoomId)
        case .join(let item):
            joinRoom(with: item)
        case .joinOpenedSpace:
            self.joinSpace()
        }
    }
    
    @available(iOS 13.0, *)
    func contextMenu(for itemData: SpaceExploreRoomListItemViewData) -> UIMenu {
        let canSendSpaceStateEvents: Bool
        if let powerLevels = self.powerLevels, let powerLevelOfCurrentUser = self.powerLevelOfCurrentUser {
            let minimumPowerLevel = powerLevels.minimumPowerLevel(forNotifications: kMXEventTypeStringRoomJoinRules, defaultPower: powerLevels.stateDefault)
            canSendSpaceStateEvents = powerLevelOfCurrentUser >= minimumPowerLevel
        } else {
            canSendSpaceStateEvents = false
        }
        
        let roomSummary = session.room(withRoomId: itemData.childInfo.childRoomId)?.summary
        let isJoined = roomSummary?.isJoined ?? false

        if itemData.childInfo.roomType == .space {
            return contextMenu(forSpace: itemData, isJoined: isJoined, canSendSpaceStateEvents: canSendSpaceStateEvents)
        } else {
            return contextMenu(forRoom: itemData, isJoined: isJoined, canSendSpaceStateEvents: canSendSpaceStateEvents)
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
        
        self.spaceRoom = self.session.spaceService.getSpace(withId: self.spaceId)?.room
        if let spaceRoom = self.spaceRoom {
            spaceRoom.state { roomState in
                self.powerLevels = roomState?.powerLevels
                self.powerLevelOfCurrentUser = self.powerLevels?.powerLevelOfUser(withUserID: self.session.myUserId)
                
            }
        }

        self.canJoin = self.session.room(withRoomId: spaceId) == nil
        
        self.currentOperation = self.session.spaceService.getSpaceChildrenForSpace(withId: self.spaceId, suggestedOnly: false, limit: nil, maxDepth: 1, paginationToken: self.nextBatch, completion: { [weak self] response in
            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let spaceSummary):
                let appendData = self.nextBatch != nil
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
                
                if appendData {
                    self.itemDataList.append(contentsOf: batchedItemDataList)
                } else {
                    self.itemDataList = batchedItemDataList
                }
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
        if let observer = self.spaceGraphObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
    
    private func setChild(withRoomId roomId: String, suggested: Bool) {
        guard let space = session.spaceService.getSpace(withId: spaceId) else {
            return
        }
        
        self.update(viewState: .loading)
        space.setChild(withRoomId: roomId, suggested: suggested) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.itemDataList = self.itemDataList.compactMap({ item in
                    if item.childInfo.childRoomId != roomId {
                        return item
                    }
                    
                    let childInfo = MXSpaceChildInfo(
                        childRoomId: item.childInfo.childRoomId,
                        isKnown: item.childInfo.isKnown,
                        roomTypeString: item.childInfo.roomTypeString,
                        roomType: item.childInfo.roomType,
                        name: item.childInfo.name,
                        topic: item.childInfo.topic,
                        canonicalAlias: item.childInfo.canonicalAlias,
                        avatarUrl: item.childInfo.avatarUrl,
                        activeMemberCount: item.childInfo.activeMemberCount,
                        autoJoin: item.childInfo.autoJoin,
                        suggested: suggested,
                        childrenIds: item.childInfo.childrenIds)
                    return SpaceExploreRoomListItemViewData(childInfo: childInfo, avatarViewData: item.avatarViewData)
                })
                self.update(viewState: .loaded(self.filteredItemDataList, self.hasMore))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func removeChild(withRoomId roomId: String) {
        guard let space = session.spaceService.getSpace(withId: spaceId) else {
            return
        }
        
        self.update(viewState: .loading)
        space.removeChild(roomId: roomId) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.itemDataList = self.itemDataList.filter { $0.childInfo.childRoomId != roomId }
                self.update(viewState: .loaded(self.filteredItemDataList, self.hasMore))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func joinRoom(with itemData: SpaceExploreRoomListItemViewData) {
        self.update(viewState: .loading)
        self.session.joinRoom(itemData.childInfo.childRoomId) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success:
                self.update(viewState: .loaded(self.filteredItemDataList, self.hasMore))
                self.coordinatorDelegate?.spaceExploreRoomViewModel(self, didJoin: itemData)
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }

    
    // MARK: - ContextMenu
    
    @available(iOS 13.0, *)
    private func contextMenu(forRoom itemData: SpaceExploreRoomListItemViewData, isJoined: Bool, canSendSpaceStateEvents: Bool) -> UIMenu {
        return UIMenu(children: [
            inviteAction(for: itemData, isJoined: isJoined),
            suggestAction(for: itemData, canSendSpaceStateEvents: canSendSpaceStateEvents),
            isJoined ? settingsAction(for: itemData, isJoined: isJoined) : joinAction(for: itemData, isJoined: isJoined),
            removeAction(for: itemData, canSendSpaceStateEvents: canSendSpaceStateEvents)
        ])
    }
    
    @available(iOS 13.0, *)
    private func contextMenu(forSpace itemData: SpaceExploreRoomListItemViewData, isJoined: Bool, canSendSpaceStateEvents: Bool) -> UIMenu {
        return UIMenu(children: [
            inviteAction(for: itemData, isJoined: isJoined),
            suggestAction(for: itemData, canSendSpaceStateEvents: canSendSpaceStateEvents),
            isJoined ? settingsAction(for: itemData, isJoined: isJoined) : joinAction(for: itemData, isJoined: isJoined),
            removeAction(for: itemData, canSendSpaceStateEvents: canSendSpaceStateEvents)
        ])
    }
    
    @available(iOS 13.0, *)
    private func inviteAction(for itemData: SpaceExploreRoomListItemViewData, isJoined: Bool) -> UIAction {
        let action = UIAction(title: VectorL10n.invite, image: Asset.Images.spaceInviteUser.image) { action in
            self.process(viewAction: .inviteTo(itemData))
        }
        if !isJoined {
            action.attributes = .disabled
        }
        return action
    }
    
    @available(iOS 13.0, *)
    private func suggestAction(for itemData: SpaceExploreRoomListItemViewData, canSendSpaceStateEvents: Bool) -> UIAction {
        let action = UIAction(title: itemData.childInfo.suggested ? VectorL10n.spacesSuggestedRoom : VectorL10n.suggest) { action in
            self.process(viewAction: .revertSuggestion(itemData))
        }
        action.state = itemData.childInfo.suggested ? .on : .off
        if !canSendSpaceStateEvents {
            action.attributes = .disabled
        }
        return action
    }
    
    @available(iOS 13.0, *)
    private func settingsAction(for itemData: SpaceExploreRoomListItemViewData, isJoined: Bool) -> UIAction {
        let action = UIAction(title: VectorL10n.roomDetailsSettings, image: Asset.Images.settingsIcon.image) { action in
            self.process(viewAction: .settings(itemData))
        }
        if !isJoined {
            action.attributes = .disabled
        }
        return action
    }
    
    @available(iOS 13.0, *)
    private func joinAction(for itemData: SpaceExploreRoomListItemViewData, isJoined: Bool) -> UIAction {
        let action = UIAction(title: VectorL10n.join) { action in
            self.process(viewAction: .join(itemData))
        }
        if isJoined {
            action.attributes = .disabled
        }
        return action
    }
    
    @available(iOS 13.0, *)
    private func removeAction(for itemData: SpaceExploreRoomListItemViewData, canSendSpaceStateEvents: Bool) -> UIAction {
        let action = UIAction(title: VectorL10n.remove, image: Asset.Images.roomContextMenuDelete.image) { action in
            self.process(viewAction: .removeChild(itemData))
        }
        action.attributes = .destructive
        if !canSendSpaceStateEvents {
            action.attributes = .disabled
        }
        return action
    }

    private func joinSpace() {
        self.update(viewState: .loading)
        
        self.currentOperation = session.joinRoom(spaceId) { [weak self] response in
            switch response {
            case .success:
                self?.spaceGraphObserver = NotificationCenter.default.addObserver(forName: MXSpaceService.didBuildSpaceGraph, object: nil, queue: OperationQueue.main, using: { [weak self] notification in
                    guard let self = self else { return }
                    
                    self.currentOperation = nil
                    if let observer = self.spaceGraphObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    self.canJoin = false
                    self.update(viewState: .loaded(self.filteredItemDataList, self.hasMore))
                })
            case .failure(let error):
                self?.update(viewState: .error(error))
            }
        }
    }
}
