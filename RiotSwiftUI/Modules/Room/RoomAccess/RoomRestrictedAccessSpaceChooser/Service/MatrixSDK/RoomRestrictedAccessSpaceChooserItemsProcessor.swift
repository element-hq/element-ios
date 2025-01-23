//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        dataSource = MatrixItemChooserRoomRestrictedAllowedParentsDataSource(roomId: roomId)
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
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        true
    }
}
