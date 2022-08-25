// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
/*
 Copyright 2020 New Vector Ltd
 
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

final class SpaceListViewModel: SpaceListViewModelType {
    // MARK: - Constants
    
    enum Constants {
        static let homeSpaceId = "home"
        static let addSpaceId = "add_space"
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let userSessionsService: UserSessionsService
    
    private var currentOperation: MXHTTPOperation?
    private var sections: [SpaceListSection] = []
    private var selectedIndexPath = IndexPath(row: 0, section: 0) {
        didSet {
            selectedItemId = itemId(with: selectedIndexPath) ?? Constants.homeSpaceId
        }
    }

    private var homeIndexPath = IndexPath(row: 0, section: 0)
    private var selectedItemId: String = Constants.homeSpaceId

    // MARK: Public

    weak var viewDelegate: SpaceListViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceListViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(userSessionsService: UserSessionsService) {
        self.userSessionsService = userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidSync(notification:)), name: MXSpaceService.didBuildSpaceGraph, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(counterDidUpdateNotificationCount(notification:)), name: MXSpaceNotificationCounter.didUpdateNotificationCount, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: NSNotification.Name.themeServiceDidChangeTheme, object: nil)
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceListViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .selectRow(at: let indexPath, from: let sourceView):
            guard selectedIndexPath != indexPath else {
                Analytics.shared.trackInteraction(.spacePanelSelectedSpace)
                return
            }
            
            let section = sections[indexPath.section]
            switch section {
            case .home:
                selectHome()
                selectedIndexPath = indexPath
                Analytics.shared.trackInteraction(.spacePanelSwitchSpace)
                update(viewState: .selectionChanged(indexPath))
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                if spaceViewData.isInvite {
                    selectInvite(with: spaceViewData.spaceId, from: sourceView)
                } else {
                    selectSpace(with: spaceViewData.spaceId)
                    selectedIndexPath = indexPath
                    Analytics.shared.trackInteraction(.spacePanelSwitchSpace)
                    update(viewState: .selectionChanged(indexPath))
                }
            case .addSpace:
                update(viewState: .selectionChanged(selectedIndexPath))
                addSpace()
            }
        case .moreAction(at: let indexPath, from: let sourceView):
            let section = sections[indexPath.section]
            switch section {
            case .home:
                coordinatorDelegate?.spaceListViewModel(self, didPressMoreForSpaceWithId: Constants.homeSpaceId, from: sourceView)
            case .addSpace: break
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                coordinatorDelegate?.spaceListViewModel(self, didPressMoreForSpaceWithId: spaceViewData.spaceId, from: sourceView)
            }
        }
    }
    
    func revertItemSelection() {
        update(viewState: .selectionChanged(selectedIndexPath))
    }
    
    func select(spaceWithId spaceId: String) {
        var foundIndexPath: IndexPath?
        
        if let spaceService = userSessionsService.mainUserSession?.matrixSession.spaceService,
           let firstRootAncestor = spaceService.firstRootAncestorForRoom(withId: spaceId) {
            foundIndexPath = indexPathOf(spaceWithId: firstRootAncestor.spaceId)
        } else {
            foundIndexPath = indexPathOf(spaceWithId: spaceId)
        }
        
        if let indexPath = foundIndexPath {
            selectSpace(with: spaceId)
            selectedIndexPath = indexPath
            update(viewState: .selectionChanged(indexPath))
        }
    }
    
    // MARK: - Private
    
    @objc private func sessionDidSync(notification: Notification) {
        loadData()
    }
    
    @objc private func counterDidUpdateNotificationCount(notification: Notification) {
        loadData()
    }
    
    @objc private func loadData() {
        guard let session = userSessionsService.mainUserSession?.matrixSession else {
            // If there is no main session, reset current selection and give an empty section list
            // It can happen when the user make a clear cache or logout
            resetList()
            return
        }

        update(viewState: .loading)
                
        let homeViewData = createHomeViewData(session: session)
        let viewDataList = getSpacesViewData(session: session)

        var sections: [SpaceListSection] = viewDataList.invites.isEmpty ? [
            .home(homeViewData),
            .spaces(viewDataList.spaces)
        ]
            :
            [
                .spaces(viewDataList.invites),
                .home(homeViewData),
                .spaces(viewDataList.spaces)
            ]

        let spacesSectionIndex = sections.count - 1
        let addSpaceViewData = createAddSpaceViewData(session: session)
        sections.append(.addSpace(addSpaceViewData))
        
        self.sections = sections
        let homeIndexPath = viewDataList.invites.isEmpty ? IndexPath(row: 0, section: 0) : IndexPath(row: 0, section: 1)
        if selectedIndexPath.section == self.homeIndexPath.section {
            selectedIndexPath = homeIndexPath
        } else if selectedItemId != itemId(with: selectedIndexPath) {
            var newSelection: IndexPath?
            let section = sections[spacesSectionIndex]
            switch section {
            case .home, .addSpace: break
            case .spaces(let viewDataList):
                var index = 0
                for itemViewData in viewDataList {
                    if itemViewData.spaceId == selectedItemId {
                        newSelection = IndexPath(row: index, section: spacesSectionIndex)
                    }
                    index += 1
                }
            }
            
            if let selection = newSelection {
                selectedIndexPath = selection
            } else {
                selectedIndexPath = homeIndexPath
                coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
            }
        }
        self.homeIndexPath = homeIndexPath
        update(viewState: .loaded(sections))
        update(viewState: .selectionChanged(selectedIndexPath))
    }
    
    private func selectHome() {
        coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
    }
    
    private func addSpace() {
        coordinatorDelegate?.spaceListViewModelDidSelectCreateSpace(self)
    }
    
    private func selectSpace(with spaceId: String) {
        coordinatorDelegate?.spaceListViewModel(self, didSelectSpaceWithId: spaceId)
    }
    
    private func selectInvite(with spaceId: String, from sourceView: UIView?) {
        coordinatorDelegate?.spaceListViewModel(self, didSelectInviteWithId: spaceId, from: sourceView)
    }
    
    private func createHomeViewData(session: MXSession) -> SpaceListItemViewData {
        let defaultAsset = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.spaceHomeIconDark : Asset.Images.spaceHomeIconLight
        let avatarViewData = AvatarViewData(matrixItemId: Constants.homeSpaceId, displayName: nil, avatarUrl: nil, mediaManager: session.mediaManager, fallbackImage: .image(defaultAsset.image, .center))
        
        let homeNotificationState = session.spaceService.notificationCounter.homeNotificationState
        let homeViewData = SpaceListItemViewData(spaceId: Constants.homeSpaceId,
                                                 title: VectorL10n.spacesHomeSpaceTitle,
                                                 avatarViewData: avatarViewData,
                                                 isInvite: false,
                                                 notificationCount: homeNotificationState.allCount,
                                                 highlightedNotificationCount: homeNotificationState.allHighlightCount)
        return homeViewData
    }
    
    private func createAddSpaceViewData(session: MXSession) -> SpaceListItemViewData {
        let defaultAsset = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.spacesAddSpaceDark : Asset.Images.spacesAddSpaceLight
        let avatarViewData = AvatarViewData(matrixItemId: Constants.addSpaceId, displayName: nil, avatarUrl: nil, mediaManager: session.mediaManager, fallbackImage: .image(defaultAsset.image, .center))
        
        let homeViewData = SpaceListItemViewData(spaceId: Constants.addSpaceId,
                                                 title: VectorL10n.spacesAddSpaceTitle,
                                                 avatarViewData: avatarViewData,
                                                 isInvite: false,
                                                 notificationCount: 0,
                                                 highlightedNotificationCount: 0)
        return homeViewData
    }

    private func getSpacesViewData(session: MXSession) -> (invites: [SpaceListItemViewData], spaces: [SpaceListItemViewData]) {
        var invites: [SpaceListItemViewData] = []
        var spaces: [SpaceListItemViewData] = []
        session.spaceService.rootSpaceSummaries.forEach { summary in
            let avatarViewData = AvatarViewData(matrixItemId: summary.roomId, displayName: summary.displayname, avatarUrl: summary.avatar, mediaManager: session.mediaManager, fallbackImage: .matrixItem(summary.roomId, summary.displayname))
            let notificationState = session.spaceService.notificationCounter.notificationState(forSpaceWithId: summary.roomId)
            let viewData = SpaceListItemViewData(spaceId: summary.roomId, title: summary.displayname,
                                                 avatarViewData: avatarViewData,
                                                 isInvite: summary.membership == .invite,
                                                 notificationCount: notificationState?.groupMissedDiscussionsCount ?? 0,
                                                 highlightedNotificationCount: notificationState?.groupMissedDiscussionsHighlightedCount ?? 0)
            if viewData.isInvite {
                invites.append(viewData)
            } else {
                spaces.append(viewData)
            }
        }
        
        return (invites, spaces)
    }
    
    private func update(viewState: SpaceListViewState) {
        viewDelegate?.spaceListViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        currentOperation?.cancel()
    }
    
    private func itemId(with indexPath: IndexPath) -> String? {
        guard selectedIndexPath.section < sections.count else {
            return Constants.homeSpaceId
        }
        let section = sections[selectedIndexPath.section]
        switch section {
        case .home:
            return Constants.homeSpaceId
        case .spaces(let viewDataList):
            guard selectedIndexPath.row < viewDataList.count else {
                return nil
            }
            let spaceViewData = viewDataList[selectedIndexPath.row]
            return spaceViewData.spaceId
        case .addSpace:
            return Constants.addSpaceId
        }
    }
    
    private func resetList() {
        sections = []
        
        let selectedIndexPath = IndexPath(row: 0, section: 0)
        
        self.selectedIndexPath = selectedIndexPath
        homeIndexPath = selectedIndexPath
        
        update(viewState: .loaded([]))
    }
    
    private func indexPathOf(spaceWithId spaceId: String) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            switch section {
            case .home: break
            case .addSpace: break
            case .spaces(let viewDataList):
                for (row, itemViewData) in viewDataList.enumerated() where itemViewData.spaceId == spaceId {
                    return IndexPath(row: row, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
}
