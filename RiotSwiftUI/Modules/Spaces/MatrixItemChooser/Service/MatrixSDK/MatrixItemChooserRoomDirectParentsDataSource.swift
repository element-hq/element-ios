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

enum MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode {
    case none
    case suggestedRoom
}

class MatrixItemChooserRoomDirectParentsDataSource: MatrixItemChooserDataSource {
    private let roomId: String
    private let preselectionMode: MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode
    
    private(set) var preselectedItemIds: Set<String>?

    init(roomId: String, preselectionMode: MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode = .none) {
        self.roomId = roomId
        self.preselectionMode = preselectionMode
    }
    
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let ancestorsIds = session.spaceService.directParentIds(ofRoomWithId: roomId)

        switch preselectionMode {
        case .none:
            preselectedItemIds = nil
        case .suggestedRoom:
            preselectedItemIds = session.spaceService.directParentIds(ofRoomWithId: roomId, whereRoomIsSuggested: true)
        }
        
        completion(Result(catching: {
            [
                MatrixListItemSectionData(title: VectorL10n.roomAccessSpaceChooserKnownSpacesSection(session.room(withRoomId: roomId)?.displayName ?? ""), items: ancestorsIds.compactMap { spaceId in
                    guard let space = session.spaceService.getSpace(withId: spaceId) else {
                        return nil
                    }
                    
                    guard let room = space.room else {
                        return nil
                    }
                    
                    return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
                }
                .sorted { $0.displayName ?? "" < $1.displayName ?? "" })
            ]
        }))
    }
}
