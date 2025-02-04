//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

class RoomAncestorSelectorViewProvider: MatrixItemChooserCoordinatorViewProvider {
    private let navTitle: String?
    
    init(navTitle: String?) {
        self.navTitle = navTitle
    }
    
    func view(with viewModel: MatrixItemChooserViewModelType.Context) -> AnyView {
        AnyView(RoomAncestorSelector(viewModel: viewModel, navTitle: navTitle))
    }
}
