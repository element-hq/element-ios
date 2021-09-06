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
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    
    private var currentOperation: MXHTTPOperation?
    private var sections: [SpaceListSection] = []
    
    // MARK: Public

    weak var viewDelegate: SpaceListViewModelViewDelegate?
    weak var coordinatorDelegate: SpaceListViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionDidSync(notification:)), name: MXSpaceService.didBuildSpaceGraph, object: nil)

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
            let section = self.sections[indexPath.section]
            switch section {
            case .home:
                self.selectHome()
                self.viewDelegate?.spaceListViewModel(self, didSelectSpaceAt: indexPath)
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                if spaceViewData.isInvite {
                    self.selectInvite(with: spaceViewData.spaceId, from: sourceView)
                } else {
                    self.selectSpace(with: spaceViewData.spaceId)
                    self.viewDelegate?.spaceListViewModel(self, didSelectSpaceAt: indexPath)
                }
            }
        case .moreAction(at: let indexPath, from: let sourceView):
            let section = self.sections[indexPath.section]
            switch section {
            case .home: break
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                self.coordinatorDelegate?.spaceListViewModel(self, didPressMoreForSpaceWithId: spaceViewData.spaceId, from: sourceView)
            }
        }
    }
    
    func revertItemSelection() {
        self.viewDelegate?.spaceListViewModelRevertSelection(self)
    }
    
    // MARK: - Private
    
    @objc private func sessionDidSync(notification: Notification) {
        loadData()
    }
    
    private func loadData() {
        guard session.mediaManager != nil else {
            return
        }

        self.update(viewState: .loading)
                
        let homeViewData = self.createHomeViewData()
        let viewDataList = getSpacesViewData()

        let sections: [SpaceListSection] = viewDataList.invites.isEmpty ? [
                .home(homeViewData),
                .spaces(viewDataList.spaces)
            ]
        :
            [
                .spaces(viewDataList.invites),
                .home(homeViewData),
                .spaces(viewDataList.spaces)
            ]
        
        self.sections = sections
        let homeIndexPath = viewDataList.invites.isEmpty ? IndexPath(row: 0, section: 0) : IndexPath(row: 0, section: 1)
        self.update(viewState: .loaded(sections, homeIndexPath))
    }
    
    private func selectHome() {
        self.coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
    }
    
    private func selectSpace(with spaceId: String) {
        self.coordinatorDelegate?.spaceListViewModel(self, didSelectSpaceWithId: spaceId)
    }
    
    private func selectInvite(with spaceId: String, from sourceView: UIView?) {
        self.coordinatorDelegate?.spaceListViewModel(self, didSelectInviteWithId: spaceId, from: sourceView)
    }
    
    private func createHomeViewData() -> SpaceListItemViewData {
        let avatarViewData = AvatarViewData(avatarUrl: nil, mediaManager: self.session.mediaManager, fallbackImage: .image(Asset.Images.spaceHomeIcon.image, .center))
        
        let homeViewData = SpaceListItemViewData(spaceId: Constants.homeSpaceId,
                                                 title: VectorL10n.spacesHomeSpaceTitle, avatarViewData: avatarViewData, isInvite: false)
        return homeViewData
    }
    
    private func getSpacesViewData() -> (invites: [SpaceListItemViewData], spaces: [SpaceListItemViewData]) {
        var invites: [SpaceListItemViewData] = []
        var spaces: [SpaceListItemViewData] = []
        session.spaceService.rootSpaceSummaries.forEach { summary in
            let avatarViewData = AvatarViewData(avatarUrl: summary.avatar, mediaManager: self.session.mediaManager, fallbackImage: .matrixItem(summary.roomId, summary.displayname))
            let viewData = SpaceListItemViewData(spaceId: summary.roomId, title: summary.displayname, avatarViewData: avatarViewData, isInvite: summary.membership == .invite)
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
}
