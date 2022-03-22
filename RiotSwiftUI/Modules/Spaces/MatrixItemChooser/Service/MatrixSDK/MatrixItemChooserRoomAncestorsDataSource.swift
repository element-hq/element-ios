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

class MatrixItemChooserRoomAncestorsDataSource: MatrixItemChooserDataSource {
    private let roomId: String
    
    var preselectedItemIds: Set<String>? { nil }

    init(roomId: String) {
        self.roomId = roomId
    }
    
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let ancestorsIds = session.spaceService.ancestorsPerRoomId[roomId] ?? []
        completion(Result(catching: {
            return [
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
