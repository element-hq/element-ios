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
import Combine

@available(iOS 14.0, *)
class MockMatrixItemChooserService: MatrixItemChooserServiceProtocol {
    
    static let mockItems = [
        MatrixListItemData(id: "!aaabaa:matrix.org", avatar: MockAvatarInput.example, displayName: "Matrix Discussion", detailText: "Descripton of this room"),
        MatrixListItemData(id: "!zzasds:matrix.org", avatar: MockAvatarInput.example, displayName: "Element Mobile", detailText: "Descripton of this room"),
        MatrixListItemData(id: "!scthve:matrix.org", avatar: MockAvatarInput.example, displayName: "Alice Personal", detailText: "Descripton of this room")
    ]
    var itemsSubject: CurrentValueSubject<[MatrixListItemData], Never>
    var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never>
    var searchText: String = ""
    var type: MatrixItemChooserType = .room
    var selectedItemIds: Set<String> = Set()

    init(type: MatrixItemChooserType = .room, items: [MatrixListItemData] = mockItems, selectedItemIndexes: [Int] = []) {
        itemsSubject = CurrentValueSubject(items)
        var selectedItemIds = Set<String>()
        for index in selectedItemIndexes {
            if index >= items.count {
                continue
            }
            
            selectedItemIds.insert(items[index].id)
        }
        selectedItemIdsSubject = CurrentValueSubject(selectedItemIds)
        self.selectedItemIds = selectedItemIds
    }
    
    func simulateSelectionForItem(at index: Int) {
        guard index < itemsSubject.value.count else {
            return
        }
        
        reverseSelectionForItem(withId: itemsSubject.value[index].id)
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
    
    func refresh() {
        
    }
}
