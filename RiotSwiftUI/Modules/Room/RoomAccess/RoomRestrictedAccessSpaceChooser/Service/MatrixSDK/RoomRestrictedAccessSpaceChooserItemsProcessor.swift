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

class RoomRestrictedAccessSpaceChooserItemsProcessor: MatrixItemChooserProcessorProtocol {
    
    // MARK: Private
    
    private let roomId: String
    private let session: MXSession

    // MARK: Setup
    
    init(roomId: String, session: MXSession) {
        self.roomId = roomId
        self.session = session
        self.dataSource = MatrixItemChooserRoomRestrictedAllowedParentsDataSource(roomId: roomId)
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource
    
    var loadingText: String? {
        VectorL10n.roomAccessSettingsScreenSettingRoomAccess
    }
    
    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        session.matrixRestClient.setRoomJoinRule(.restricted, forRoomWithId: roomId, allowedParentIds: itemsIds) { response in
            switch response {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(()))
            }
        }
    }
    
    func isItemIncluded(_ item: (MatrixListItemData)) -> Bool {
        return true
    }
}
