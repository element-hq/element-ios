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

protocol SpaceListViewModelViewDelegate: AnyObject {
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didUpdateViewState viewSate: SpaceListViewState)
}

protocol SpaceListViewModelCoordinatorDelegate: AnyObject {
    func spaceListViewModelDidSelectHomeSpace(_ viewModel: SpaceListViewModelType)
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didSelectSpaceWithId spaceId: String)
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didSelectInviteWithId spaceId: String, from sourceView: UIView?)
    func spaceListViewModel(_ viewModel: SpaceListViewModelType, didPressMoreForSpaceWithId spaceId: String, from sourceView: UIView)
    func spaceListViewModelDidSelectCreateSpace(_ viewModel: SpaceListViewModelType)
}

/// Protocol describing the view model used by `SpaceListViewController`
protocol SpaceListViewModelType {        
        
    var viewDelegate: SpaceListViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceListViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SpaceListViewAction)
    func revertItemSelection()
    func select(spaceWithId spaceId: String)
}
