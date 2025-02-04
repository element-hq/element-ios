// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

extension Sequence {
    func group<GroupID: Hashable>(by keyPath: KeyPath<Element, GroupID>) -> [GroupID: [Element]] {
        var result: [GroupID: [Element]] = .init()
        
        for item in self {
            let groupId = item[keyPath: keyPath]
            result[groupId] = (result[groupId] ?? []) + [item]
        }
        
        return result
    }
}
