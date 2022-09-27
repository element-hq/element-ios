//
// Copyright 2022 New Vector Ltd
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

class MatrixItemChooserDirectChildrenDataSource: MatrixItemChooserDataSource {
    // MARK: - Private
    
    private let parentId: String

    // MARK: - Setup
    
    init(parentId: String) {
        self.parentId = parentId
    }

    // MARK: - MatrixItemChooserDataSource
    
    var preselectedItemIds: Set<String>? { nil }

    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let space = session.spaceService.getSpace(withId: parentId)
        let children: [MatrixListItemData] = space?.childRoomIds.compactMap { roomId in
            guard let room = session.room(withRoomId: roomId), !room.isDirect else {
                return nil
            }
            
            return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
        } ?? []
        completion(Result(catching: {
            [
                MatrixListItemSectionData(items: children)
            ]
        }))
    }
}
