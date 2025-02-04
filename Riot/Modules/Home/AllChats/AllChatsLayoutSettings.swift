// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class AllChatsLayoutSettings: NSObject, NSCoding {
    
    fileprivate enum Constants {
        static let sectionsKey = "sections"
        static let filtersKey = "filters"
        static let sortingKey = "sorting"
    }
    
    let sections: AllChatsLayoutSectionType
    let filters: AllChatsLayoutFilterType
    let sorting: AllChatsLayoutSortingType
    
    init(sections: AllChatsLayoutSectionType = [],
         filters: AllChatsLayoutFilterType = [],
         sorting: AllChatsLayoutSortingType = .activity) {
        self.sections = sections
        self.filters = filters
        self.sorting = sorting
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(Int(sections.rawValue), forKey: Constants.sectionsKey)
        coder.encode(Int(filters.rawValue), forKey: Constants.filtersKey)
        coder.encode(Int(sorting.rawValue), forKey: Constants.sortingKey)
    }
    
    required init?(coder: NSCoder) {
        self.sections = AllChatsLayoutSectionType(rawValue: UInt(coder.decodeInteger(forKey: Constants.sectionsKey)))
        self.filters = AllChatsLayoutFilterType(rawValue: UInt(coder.decodeInteger(forKey: Constants.filtersKey)))
        self.sorting = AllChatsLayoutSortingType(rawValue: UInt(coder.decodeInteger(forKey: Constants.sortingKey))) ?? .activity
    }
}
