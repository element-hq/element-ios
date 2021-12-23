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

protocol MatrixItemChooserProcessorProtocol {
    var dataType: MatrixItemChooserType { get }
    func computeSelection(withIds itemsIds:[String], completion: @escaping (Result<Void, Error>) -> Void)
    func isItemIncluded(_ item: (MatrixListItemData)) -> Bool
}

@available(iOS 14.0, *)
class MatrixItemChooserService: MatrixItemChooserServiceProtocol {

    // MARK: - Properties
    
    // MARK: Private
    
    private let processingQueue = DispatchQueue(label: "org.matrix.element.MatrixItemChooserService.processingQueue")
    private let completionQueue = DispatchQueue.main

    private let session: MXSession
    private let items: [MatrixListItemData]
    private var filteredItems: [MatrixListItemData] {
        didSet {
            itemsSubject.send(filteredItems)
        }
    }
    private var selectedItemIds: Set<String>
    private let itemsProcessor: MatrixItemChooserProcessorProtocol?
    
    // MARK: Public
    
    private(set) var type: MatrixItemChooserType
    private(set) var itemsSubject: CurrentValueSubject<[MatrixListItemData], Never>
    private(set) var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never>
    var searchText: String = "" {
        didSet {
            refresh()
        }
    }
    
    // MARK: - Setup
    
    init(session: MXSession, selectedItemIds: [String], itemsProcessor: MatrixItemChooserProcessorProtocol?) {
        self.session = session
        self.type = itemsProcessor?.dataType ?? .room
        switch type {
        case .people:
            self.items = session.users().map { user in
                MatrixListItemData(mxUser: user)
            }
        case .room:
            self.items = session.rooms.compactMap { room in
                if room.summary.roomType == .space || room.isDirect {
                    return nil
                }
                
                return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
            }
        }
        self.itemsSubject = CurrentValueSubject(self.items)
        self.filteredItems = []
        
        self.selectedItemIds = Set(selectedItemIds)
        self.selectedItemIdsSubject = CurrentValueSubject(self.selectedItemIds)
        self.itemsProcessor = itemsProcessor
        
        refresh()
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
    
    func processSelection(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let selectionProcessor = self.itemsProcessor else {
            completion(Result.success(()))
            return
        }
        
        selectionProcessor.computeSelection(withIds: Array(selectedItemIds), completion: completion)
    }
    
    func refresh() {
        self.processingQueue.async { [weak self] in
            guard let self = self else { return }
            let filteredItems = self.filter(items: self.items)
            
            self.completionQueue.async {
                self.filteredItems = filteredItems
            }
        }
    }

    // MARK: - Private
    
    private func filter(items: [MatrixListItemData]) -> [MatrixListItemData] {
        if searchText.isEmpty {
            if let selectionProcessor = self.itemsProcessor {
                return items.filter {
                    selectionProcessor.isItemIncluded($0)
                }
            } else {
                return items
            }
        } else {
            let lowercasedSearchText = self.searchText.lowercased()
            if let selectionProcessor = self.itemsProcessor {
                return items.filter {
                    selectionProcessor.isItemIncluded($0) && ($0.id.lowercased().contains(lowercasedSearchText) || ($0.displayName ?? "").lowercased().contains(lowercasedSearchText))
                }
            } else {
                return items.filter {
                    $0.id.lowercased().contains(lowercasedSearchText) || ($0.displayName ?? "").lowercased().contains(lowercasedSearchText)
                }
            }
        }
    }
}

fileprivate extension MatrixListItemData {
    
    init(mxUser: MXUser) {
        self.init(id: mxUser.userId, avatar: mxUser.avatarData, displayName: mxUser.displayname, detailText: mxUser.userId)
    }
    
    init(mxRoom: MXRoom, spaceService: MXSpaceService) {
        let parentSapceIds = mxRoom.summary.parentSpaceIds ?? Set()
        let detailText: String?
        if parentSapceIds.isEmpty {
            detailText = nil
        } else {
            if let spaceName = spaceService.getSpace(withId: parentSapceIds.first ?? "")?.summary?.displayname {
                let count = parentSapceIds.count - 1
                switch count {
                case 0:
                    detailText = VectorL10n.spacesCreationInSpacename(spaceName)
                case 1:
                    detailText = VectorL10n.spacesCreationInSpacenamePlusOne(spaceName)
                default:
                    detailText = VectorL10n.spacesCreationInSpacenamePlusMany(spaceName, "\(count)")
                }
            } else {
                if parentSapceIds.count > 1 {
                    detailText = VectorL10n.spacesCreationInManySpaces("\(parentSapceIds.count)")
                } else {
                    detailText = VectorL10n.spacesCreationInOneSpace
                }
            }
        }
        self.init(id: mxRoom.roomId, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayname, detailText: detailText)
    }
    
}
