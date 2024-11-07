//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class MatrixItemChooserUsersDataSource: MatrixItemChooserDataSource {
    var preselectedItemIds: Set<String>? { nil }

    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        completion(Result(catching: {
            [
                MatrixListItemSectionData(items: session.users().map { user in
                    MatrixListItemData(mxUser: user)
                })
            ]
        }))
    }
}
