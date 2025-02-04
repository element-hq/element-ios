// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
