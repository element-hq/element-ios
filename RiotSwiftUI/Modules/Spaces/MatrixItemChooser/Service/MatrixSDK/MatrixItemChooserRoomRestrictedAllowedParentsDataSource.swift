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

class MatrixItemChooserRoomRestrictedAllowedParentsDataSource: MatrixItemChooserDataSource {
    private let roomId: String
    private var allowedParentIds: [String] = []
    
    var preselectedItemIds: Set<String>? {
        Set(allowedParentIds)
    }

    init(roomId: String) {
        self.roomId = roomId
    }
    
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        guard let room = session.room(withRoomId: roomId) else {
            return
        }
        
        room.state { [weak self] state in
            guard let self = self else { return }
            
            let joinRuleEvent = state?.stateEvents(with: .roomJoinRules)?.last
            let allowContent: [[String: String]] = joinRuleEvent?.wireContent[kMXJoinRulesContentKeyAllow] as? [[String: String]] ?? []
            self.allowedParentIds = allowContent.compactMap { allowDictionnary in
                guard let type = allowDictionnary[kMXJoinRulesContentKeyType], type == kMXEventTypeStringRoomMembership else {
                    return nil
                }
                
                return allowDictionnary[kMXJoinRulesContentKeyRoomId]
            }

            let ancestorsId = session.spaceService.ancestorsPerRoomId[self.roomId] ?? []
            var sections = [
                MatrixListItemSectionData(
                    title: VectorL10n.roomAccessSpaceChooserKnownSpacesSection(room.displayName ?? ""),
                    items: ancestorsId.compactMap { spaceId in
                        guard let space = session.spaceService.getSpace(withId: spaceId) else {
                            return nil
                        }

                        guard let room = space.room else {
                            return nil
                        }
                        
                        return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
                    }.sorted { $0.displayName ?? "" < $1.displayName ?? "" }
                )
            ]
            
            var unknownParents = self.allowedParentIds
            for roomId in ancestorsId {
                if let index = unknownParents.firstIndex(of: roomId) {
                    unknownParents.remove(at: index)
                }
            }
            if !unknownParents.isEmpty {
                sections.append(MatrixListItemSectionData(
                    title: VectorL10n.roomAccessSpaceChooserOtherSpacesSection,
                    infoText: VectorL10n.roomAccessSpaceChooserOtherSpacesSectionInfo(room.displayName ?? ""),
                    items: unknownParents.compactMap { roomId in
                        MatrixListItemData(
                            id: roomId,
                            type: .space,
                            avatar: AvatarInput(mxContentUri: roomId, matrixItemId: roomId, displayName: roomId),
                            displayName: roomId,
                            detailText: nil
                        )
                    }
                ))
            }
            
            completion(Result(catching: {
                sections
            }))
        }
    }
}
