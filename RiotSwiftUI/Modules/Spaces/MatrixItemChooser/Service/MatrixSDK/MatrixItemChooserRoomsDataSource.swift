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

class MatrixItemChooserRoomsDataSource: MatrixItemChooserDataSource {
    var preselectedItemIds: Set<String>? { nil }

    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        var favouriteRooms: [MatrixListItemData] = []
        var peopleRooms: [MatrixListItemData] = []
        var rooms: [MatrixListItemData] = []
        
        for room in session.rooms where room.summary.roomType != .space {
            let currentTag = room.accountData.tags?.values.first
            if currentTag?.name == kMXRoomTagFavourite {
                favouriteRooms.append(MatrixListItemData(mxRoom: room, spaceService: session.spaceService))
            } else if room.summary.isDirect {
                peopleRooms.append(MatrixListItemData(mxRoom: room, spaceService: session.spaceService))
            } else {
                rooms.append(MatrixListItemData(mxRoom: room, spaceService: session.spaceService))
            }
        }
        
        favouriteRooms = sortedArray(favouriteRooms)
        peopleRooms = sortedArray(peopleRooms)
        rooms = sortedArray(rooms)
        
        var sections: [MatrixListItemSectionData] = []
        if (!favouriteRooms.isEmpty) {
            sections.append(MatrixListItemSectionData(title: VectorL10n.titleFavourites, items: favouriteRooms))
        }
        if (!peopleRooms.isEmpty) {
            sections.append(MatrixListItemSectionData(title: VectorL10n.titlePeople, items: peopleRooms))
        }
        if (!rooms.isEmpty) {
            sections.append(MatrixListItemSectionData(title: VectorL10n.titlePeople, items: rooms))
        }

        completion(Result(catching: { sections }))
    }
    
    // MARK : - Private
    
    private func sortedArray(_ array: [MatrixListItemData]) -> [MatrixListItemData] {
        return array.sorted { item1, item2 in
            guard let displayName1 = item1.displayName, let displayName2 = item2.displayName else {
                return true
            }
            return displayName1.lowercased() <= displayName2.lowercased()
        }
    }
}
