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

/// RoomSuggestionSpaceChooserItemsProcessor operation error
public enum RoomSuggestionSpaceChooserItemsProcessorError: Int, Error {
    case parentNotFound
}

class RoomSuggestionSpaceChooserItemsProcessor: MatrixItemChooserProcessorProtocol {
    
    // MARK: Private
    
    private let roomId: String
    private let session: MXSession
    private var computationErrorList: [Error] = []
    private var didBuildSpaceGraphObserver: Any?

    // MARK: Setup
    
    init(roomId: String, session: MXSession) {
        self.roomId = roomId
        self.session = session
        self.dataSource = MatrixItemChooserRoomDirectParentsDataSource(roomId: roomId, preselectionMode: .suggestedRoom)
    }
    
    deinit {
        if let observer = self.didBuildSpaceGraphObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource
    
    var loadingText: String? { nil }
    
    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let unselectedItems: [String]
        let selectedItems: [String]
        if let preselectedItems = dataSource.preselectedItemIds {
            unselectedItems = preselectedItems.compactMap({ itemId in
                return !itemsIds.contains(itemId) ? itemId : nil
            })
            selectedItems = itemsIds.compactMap { itemId in
                return !preselectedItems.contains(itemId) ? itemId : nil
            }
        } else {
            unselectedItems = []
            selectedItems = itemsIds
        }
        
        computationErrorList = []
        
        guard !unselectedItems.isEmpty || !selectedItems.isEmpty else {
            completion(.success(()))
            return
        }
        
        setRoom(suggested: false, forParentsWithId: unselectedItems) { [weak self] in
            self?.setRoom(suggested: true, forParentsWithId: selectedItems, completion: { [weak self] in
                guard let self = self else { return }
                
                if let firstError = self.computationErrorList.first {
                    completion(.failure(firstError))
                } else {
                    self.didBuildSpaceGraphObserver = NotificationCenter.default.addObserver(forName: MXSpaceService.didBuildSpaceGraph, object: nil, queue: OperationQueue.main) { [weak self] notification in
                        guard let self = self else { return }
                        
                        if let observer = self.didBuildSpaceGraphObserver {
                            NotificationCenter.default.removeObserver(observer)
                            self.didBuildSpaceGraphObserver = nil
                        }
                        
                        completion(.success(()))
                    }
                }
            })
        }
    }
    
    func isItemIncluded(_ item: (MatrixListItemData)) -> Bool {
        return true
    }
    
    // MARK: - Private
    
    /// (Un)suggest room for spaces which ID is in `parentIds`.
    /// Recurse to the next index once done.
    private func setRoom(suggested: Bool, forParentsWithId parentIds: [String], at index: Int = 0, completion: @escaping () -> Void) {
        guard index < parentIds.count else {
            completion()
            return
        }
        
        guard let space = session.spaceService.getSpace(withId: parentIds[index]) else {
            computationErrorList.append(RoomSuggestionSpaceChooserItemsProcessorError.parentNotFound)
            setRoom(suggested: suggested, forParentsWithId: parentIds, at: index + 1, completion: completion)
            return
        }
        
        space.setChild(withRoomId: roomId, suggested: suggested) { [weak self] response in
            guard let self = self else { return }
            
            if let error = response.error {
                self.computationErrorList.append(error)
            }
            
            self.setRoom(suggested: suggested, forParentsWithId: parentIds, at: index + 1, completion: completion)
        }
    }
}
