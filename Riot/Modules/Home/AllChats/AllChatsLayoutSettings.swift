// 
// Copyright 2022 New Vector Ltd
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
