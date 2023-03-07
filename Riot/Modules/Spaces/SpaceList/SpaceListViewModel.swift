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
        static let homeSpaceId: String = "home"
        static let addSpaceId: String = "add_space"
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let userSessionsService: UserSessionsService
    
    private var currentOperation: MXHTTPOperation?
    private var sections: [SpaceListSection] = []
    private var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0) {
        didSet {
            self.selectedItemId = self.itemId(with: self.selectedIndexPath) ?? Constants.homeSpaceId
        }
    }
    private var homeIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    private var selectedItemId: String = Constants.homeSpaceId

    // MARK: Public

    weak var viewDelegate: SpaceListViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceListViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(userSessionsService: UserSessionsService) {
        self.userSessionsService = userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionDidSync(notification:)), name: MXSpaceService.didBuildSpaceGraph, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.counterDidUpdateNotificationCount(notification:)), name: MXSpaceNotificationCounter.didUpdateNotificationCount, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadData), name: NSNotification.Name.themeServiceDidChangeTheme, object: nil)

    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .selectRow(at: let indexPath, from: let sourceView):
            guard self.selectedIndexPath != indexPath else {
                Analytics.shared.trackInteraction(.spacePanelSelectedSpace)
                return
            }
            
            let section = self.sections[indexPath.section]
            switch section {
            case .home:
                self.selectHome()
                self.selectedIndexPath = indexPath
                Analytics.shared.trackInteraction(.spacePanelSwitchSpace)
                self.update(viewState: .selectionChanged(indexPath))
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                if spaceViewData.isInvite {
                    self.selectInvite(with: spaceViewData.spaceId, from: sourceView)
                } else {
                    self.selectSpace(with: spaceViewData.spaceId)
                    self.selectedIndexPath = indexPath
                    Analytics.shared.trackInteraction(.spacePanelSwitchSpace)
                    self.update(viewState: .selectionChanged(indexPath))
                }
            case .addSpace:
                self.update(viewState: .selectionChanged(self.selectedIndexPath))
                addSpace()
            }
        case .moreAction(at: let indexPath, from: let sourceView):
            let section = self.sections[indexPath.section]
            switch section {
            case .home:
                self.coordinatorDelegate?.spaceListViewModel(self, didPressMoreForSpaceWithId: Constants.homeSpaceId, from: sourceView)
            case .addSpace: break
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                self.coordinatorDelegate?.spaceListViewModel(self, didPressMoreForSpaceWithId: spaceViewData.spaceId, from: sourceView)
            }
        }
    }
    
    func revertItemSelection() {
        self.update(viewState: .selectionChanged(self.selectedIndexPath))
    }
    
    func select(spaceWithId spaceId: String) {
        var foundIndexPath: IndexPath?
        
        if let spaceService = self.userSessionsService.mainUserSession?.matrixSession.spaceService,
           let firstRootAncestor = spaceService.firstRootAncestorForRoom(withId: spaceId) {
            foundIndexPath = indexPathOf(spaceWithId: firstRootAncestor.spaceId)
        } else {
            foundIndexPath = indexPathOf(spaceWithId: spaceId)
        }
        
        if let indexPath = foundIndexPath {
            self.selectSpace(with: spaceId)
            self.selectedIndexPath = indexPath
            self.update(viewState: .selectionChanged(indexPath))
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
        guard let session = self.userSessionsService.mainUserSession?.matrixSession else {
            // If there is no main session, reset current selection and give an empty section list
            // It can happen when the user make a clear cache or logout 
            self.resetList()
            return
        }

        self.update(viewState: .loading)
                
        let homeViewData = self.createHomeViewData(session: session)
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
        let addSpaceViewData = self.createAddSpaceViewData(session: session)
        sections.append(.addSpace(addSpaceViewData))
        
        self.sections = sections
        let homeIndexPath = viewDataList.invites.isEmpty ? IndexPath(row: 0, section: 0) : IndexPath(row: 0, section: 1)
        if self.selectedIndexPath.section == self.homeIndexPath.section {
            self.selectedIndexPath = homeIndexPath
        } else if self.selectedItemId != self.itemId(with: self.selectedIndexPath) {
            var newSelection: IndexPath?
            let section = sections[spacesSectionIndex]
            switch section {
            case .home, .addSpace: break
            case .spaces(let viewDataList):
                var index = 0
                for itemViewData in viewDataList {
                    if itemViewData.spaceId == self.selectedItemId {
                        newSelection = IndexPath(row: index, section: spacesSectionIndex)
                    }
                    index += 1
                }
            }
            
            if let selection = newSelection {
                self.selectedIndexPath = selection
            } else {
                self.selectedIndexPath = homeIndexPath
                self.coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
            }
        }
        self.homeIndexPath = homeIndexPath
        self.update(viewState: .loaded(sections))
        self.update(viewState: .selectionChanged(self.selectedIndexPath))
    }
    
    private func selectHome() {
        self.coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
    }
    
    private func addSpace() {
        self.coordinatorDelegate?.spaceListViewModelDidSelectCreateSpace(self)
    }
    
    private func selectSpace(with spaceId: String) {
        self.coordinatorDelegate?.spaceListViewModel(self, didSelectSpaceWithId: spaceId)
    }
    
    private func selectInvite(with spaceId: String, from sourceView: UIView?) {
        self.coordinatorDelegate?.spaceListViewModel(self, didSelectInviteWithId: spaceId, from: sourceView)
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
            let avatarViewData = AvatarViewData(matrixItemId: summary.roomId, displayName: summary.displayName, avatarUrl: summary.avatar, mediaManager: session.mediaManager, fallbackImage: .matrixItem(summary.roomId, summary.displayName))
            let notificationState = session.spaceService.notificationCounter.notificationState(forSpaceWithId: summary.roomId)
            let viewData = SpaceListItemViewData(spaceId: summary.roomId, title: summary.displayName,
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
        self.viewDelegate?.spaceListViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
    
    private func itemId(with indexPath: IndexPath) -> String? {
        guard self.selectedIndexPath.section < self.sections.count else {
            return Constants.homeSpaceId
        }
        let section = self.sections[self.selectedIndexPath.section]
        switch section {
        case .home:
            return Constants.homeSpaceId
        case .spaces(let viewDataList):
            guard self.selectedIndexPath.row < viewDataList.count else {
                return nil
            }
            let spaceViewData = viewDataList[self.selectedIndexPath.row]
            return spaceViewData.spaceId
        case .addSpace:
            return Constants.addSpaceId
        }
    }
    
    private func resetList() {
        self.sections = []
        
        let selectedIndexPath = IndexPath(row: 0, section: 0)
        
        self.selectedIndexPath = selectedIndexPath
        self.homeIndexPath = selectedIndexPath
        
        self.update(viewState: .loaded([]))
    }
    
    private func indexPathOf(spaceWithId spaceId: String) -> IndexPath? {
        for (sectionIndex, section) in self.sections.enumerated() {
            switch section {
            case .home: break
            case .addSpace:  break
            case .spaces(let viewDataList):
                for (row, itemViewData) in viewDataList.enumerated() where itemViewData.spaceId == spaceId {
                    return IndexPath(row: row, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
}
