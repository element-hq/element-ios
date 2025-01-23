//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class SpaceCreationInviteUsersItemsProcessor: MatrixItemChooserProcessorProtocol {
    // MARK: Private
    
    private let creationParams: SpaceCreationParameters
    
    // MARK: Setup
    
    init(creationParams: SpaceCreationParameters) {
        self.creationParams = creationParams
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource = MatrixItemChooserUsersDataSource()
    
    var loadingText: String? {
        nil
    }

    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        creationParams.inviteType = .userId
        creationParams.userIdInvites = itemsIds
        completion(.success(()))
    }
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        true
    }
}
