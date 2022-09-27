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
