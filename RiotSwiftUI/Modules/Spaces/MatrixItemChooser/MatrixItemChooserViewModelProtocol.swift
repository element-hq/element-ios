//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol MatrixItemChooserViewModelProtocol {
    var completion: ((MatrixItemChooserViewModelResult) -> Void)? { get set }
    static func makeMatrixItemChooserViewModel(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?, selectionHeader: MatrixItemChooserSelectionHeader?) -> MatrixItemChooserViewModelProtocol
    var context: MatrixItemChooserViewModelType.Context { get }
}
