//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

protocol MatrixItemChooserServiceProtocol {
    var sectionsSubject: CurrentValueSubject<[MatrixListItemSectionData], Never> { get }
    var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never> { get }
    var searchText: String { get set }
    var loadingText: String? { get }
    var itemCount: Int { get }

    func reverseSelectionForItem(withId itemId: String)
    func processSelection(completion: @escaping (Result<Void, Error>) -> Void)
    func refresh()
    func selectAllItems()
    func deselectAllItems()
}
