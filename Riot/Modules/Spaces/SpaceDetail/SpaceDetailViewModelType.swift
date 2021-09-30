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

protocol SpaceDetailViewModelViewDelegate: AnyObject {
    func spaceDetailViewModel(_ viewModel: SpaceDetailViewModelType, didUpdateViewState viewSate: SpaceDetailViewState)
}

protocol SpaceDetailModelViewModelCoordinatorDelegate: AnyObject {
    func spaceDetailViewModelDidCancel(_ viewModel: SpaceDetailViewModelType)
    func spaceDetailViewModelDidDismiss(_ viewModel: SpaceDetailViewModelType)
    func spaceDetailViewModelDidOpen(_ viewModel: SpaceDetailViewModelType)
    func spaceDetailViewModelDidJoin(_ viewModel: SpaceDetailViewModelType)
}

/// Protocol describing the view model used by `SpaceDetailViewController`
protocol SpaceDetailViewModelType {

    var viewDelegate: SpaceDetailViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceDetailModelViewModelCoordinatorDelegate? { get set }

    func process(viewAction: SpaceDetailViewAction)
}
