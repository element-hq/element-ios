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
class SpaceCreationMatrixItemChooserService: SpaceCreationMatrixItemChooserServiceProtocol {

    // MARK: - Properties
    
    // MARK: Private
    
    private let processingQueue = DispatchQueue(label: "org.matrix.element.SpaceCreationMatrixItemChooserService.processingQueue")
    private let completionQueue = DispatchQueue.main

    private let session: MXSession
    private let items: [SpaceCreationMatrixItem]
    private var filteredItems: [SpaceCreationMatrixItem] {
        didSet {
            itemsSubject.send(filteredItems)
        }
    }
    private var selectedItemIds: Set<String>
    
    // MARK: Public
    
    private(set) var type: SpaceCreationMatrixItemType
    private(set) var itemsSubject: CurrentValueSubject<[SpaceCreationMatrixItem], Never>
    private(set) var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never>
    var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                filteredItems = items
            } else {
                self.processingQueue.async {
                    let lowercasedSearchText = self.searchText.lowercased()
                    let filteredItems = self.items.filter { $0.id.lowercased().contains(lowercasedSearchText) || ($0.displayName ?? "").lowercased().contains(lowercasedSearchText) }
                    
                    self.completionQueue.async {
                        self.filteredItems = filteredItems
                    }
                }
            }
        }
    }
    
    // MARK: - Setup
    
    init(session: MXSession, type: SpaceCreationMatrixItemType, selectedItemIds: [String]) {
        self.session = session
        self.type = type
        switch type {
        case .people:
            self.items = session.users().map { user in
                SpaceCreationMatrixItem(mxUser: user)
            }
        case .room:
            self.items = session.rooms.compactMap { room in
                if room.summary.roomType == .space || room.isDirect {
                    return nil
                }
                
                return SpaceCreationMatrixItem(mxRoom: room)
            }
        }
        self.itemsSubject = CurrentValueSubject(self.items)
        self.filteredItems = self.items
        
        self.selectedItemIds = Set(selectedItemIds)
        self.selectedItemIdsSubject = CurrentValueSubject(self.selectedItemIds)
    }
    
    // MARK: - Public
    
    func reverseSelectionForItem(withId itemId: String) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
        selectedItemIdsSubject.send(selectedItemIds)
    }

}

fileprivate extension SpaceCreationMatrixItem {
    
    init(mxUser: MXUser) {
        self.init(id: mxUser.userId, avatar: mxUser.avatarData, displayName: mxUser.displayname, detailText: mxUser.userId)
    }
    
    init(mxRoom: MXRoom) {
        self.init(id: mxRoom.roomId, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayname, detailText: mxRoom.summary.roomId)
    }
    
}
