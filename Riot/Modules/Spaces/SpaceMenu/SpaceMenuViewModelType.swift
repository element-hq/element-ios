// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
