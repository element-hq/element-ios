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
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: SpaceListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .selectRow(at: let indexPath):
            let section = self.sections[indexPath.section]
            switch section {
            case .home:
                self.selectHome()
            case .spaces(let viewDataList):
                let spaceViewData = viewDataList[indexPath.row]
                self.selectSpace(with: spaceViewData.spaceId)
            }
        }
    }
    
    // MARK: - Private
    
    private func loadData() {

        self.update(viewState: .loading)
                
        let homeViewData = self.createHomeViewData()
        
        // TODO: Manage space list
        let spacesViewDataList: [SpaceListItemViewData] = [
        ]
        
        let sections: [SpaceListSection] = [
            .home(homeViewData),
            .spaces(spacesViewDataList)
        ]
        
        self.sections = sections
        
        self.update(viewState: .loaded(sections))
    }
    
    private func selectHome() {
        self.coordinatorDelegate?.spaceListViewModelDidSelectHomeSpace(self)
    }
    
    private func selectSpace(with spaceId: String) {
        self.coordinatorDelegate?.spaceListViewModel(self, didSelectSpaceWithId: spaceId)
    }
    
    private func createHomeViewData() -> SpaceListItemViewData {
        let avatarViewData = AvatarViewData(avatarUrl: nil, mediaManager: self.session.mediaManager, fallbackImage: .image(Asset.Images.spaceHomeIcon.image, .center))
        
        let homeViewData = SpaceListItemViewData(spaceId: "home",
                                                 title: VectorL10n.spacesHomeSpaceTitle, avatarViewData: avatarViewData)
        return homeViewData
    }
    
    private func update(viewState: SpaceListViewState) {
        self.viewDelegate?.spaceListViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
