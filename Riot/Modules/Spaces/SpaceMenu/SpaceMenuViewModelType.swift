// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

protocol SpaceMenuViewModelViewDelegate: AnyObject {
    func spaceMenuViewModel(_ viewModel: SpaceMenuViewModelType, didUpdateViewState viewSate: SpaceMenuViewState)
}

protocol SpaceMenuModelViewModelCoordinatorDelegate: AnyObject {
    func spaceMenuViewModelDidDismiss(_ viewModel: SpaceMenuViewModelType)
    func spaceMenuViewModel(_ viewModel: SpaceMenuViewModelType, didSelectItemWith action: SpaceMenuListItemAction)
}

/// Protocol describing the view model used by `SpaceMenuViewController`
protocol SpaceMenuViewModelType {
    var menuItems: [SpaceMenuListItemViewData] { get }
    
    var viewDelegate: SpaceMenuViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceMenuModelViewModelCoordinatorDelegate? { get set }

    func process(viewAction: SpaceMenuViewAction)
}
