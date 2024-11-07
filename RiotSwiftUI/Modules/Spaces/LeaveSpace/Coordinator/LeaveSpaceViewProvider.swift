//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class LeaveSpaceViewProvider: MatrixItemChooserCoordinatorViewProvider {
    private let navTitle: String?
    
    init(navTitle: String?) {
        self.navTitle = navTitle
    }
    
    func view(with viewModel: MatrixItemChooserViewModelType.Context) -> AnyView {
        AnyView(LeaveSpace(viewModel: viewModel, navTitle: navTitle))
    }
}
