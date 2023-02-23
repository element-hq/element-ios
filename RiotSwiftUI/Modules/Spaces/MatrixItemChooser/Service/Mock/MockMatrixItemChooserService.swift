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

class MockMatrixItemChooserService: MatrixItemChooserServiceProtocol {
    static let mockSections = [
        MatrixListItemSectionData(title: "Section 1", infoText: "This is the first section with a very long description in order to check multi line description", items: [
            MatrixListItemData(id: "!aaabaa:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #1 section #1", detailText: "Descripton of this room"),
            MatrixListItemData(id: "!zzasds:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #2 section #1", detailText: "Descripton of this room"),
            MatrixListItemData(id: "!scthve:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #3 section #1", detailText: "Descripton of this room")
        ]),
        MatrixListItemSectionData(title: "Section 2", infoText: nil, items: [
            MatrixListItemData(id: "!asdasd:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #1 section #2", detailText: "Descripton of this room"),
            MatrixListItemData(id: "!lkjlkjl:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #2 section #2", detailText: "Descripton of this room"),
            MatrixListItemData(id: "!vvlkvjlk:matrix.org", type: .room, avatar: MockAvatarInput.example, displayName: "Item #3 section #2", detailText: "Descripton of this room")
        ])
    ]
    var sectionsSubject: CurrentValueSubject<[MatrixListItemSectionData], Never>
    var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never>
    var searchText = ""
    var selectedItemIds: Set<String> = Set()
    var loadingText: String? {
        nil
    }

    var itemCount: Int {
        var itemCount = 0
        for section in sectionsSubject.value {
            itemCount += section.items.count
        }
        return itemCount
    }

    init(type: MatrixItemChooserType = .room, sections: [MatrixListItemSectionData] = mockSections, selectedItemIndexPaths: [IndexPath] = []) {
        sectionsSubject = CurrentValueSubject(sections)
        var selectedItemIds = Set<String>()
        for indexPath in selectedItemIndexPaths {
            guard indexPath.section < sections.count, indexPath.row < sections[indexPath.section].items.count else {
                continue
            }
            
            selectedItemIds.insert(sections[indexPath.section].items[indexPath.row].id)
        }
        selectedItemIdsSubject = CurrentValueSubject(selectedItemIds)
        self.selectedItemIds = selectedItemIds
    }
    
    func simulateSelectionForItem(at indexPath: IndexPath) {
        guard indexPath.section < sectionsSubject.value.count, indexPath.row < sectionsSubject.value[indexPath.section].items.count else {
            return
        }
        
        selectedItemIds.insert(sectionsSubject.value[indexPath.section].items[indexPath.row].id)
        selectedItemIdsSubject.send(selectedItemIds)
    }
    
    func reverseSelectionForItem(withId itemId: String) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
        selectedItemIdsSubject.send(selectedItemIds)
    }
    
    func processSelection(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(Result.success(()))
    }
    
    func refresh() { }
    
    func selectAllItems() {
        var newSelection: Set<String> = Set()
        for section in sectionsSubject.value {
            for item in section.items {
                newSelection.insert(item.id)
            }
        }
        selectedItemIds = newSelection
        selectedItemIdsSubject.send(selectedItemIds)
    }
    
    func deselectAllItems() {
        selectedItemIds = Set()
        selectedItemIdsSubject.send(selectedItemIds)
    }
}
