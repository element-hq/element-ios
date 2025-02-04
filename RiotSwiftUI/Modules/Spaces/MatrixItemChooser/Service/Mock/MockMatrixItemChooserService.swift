//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
