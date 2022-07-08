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

//struct AllChatLayoutSectionType: OptionSet {
//    let rawValue: UInt
//    
//    static let recents = AllChatLayoutSectionType(rawValue: 1 << 0)
//    static let favourites = AllChatLayoutSectionType(rawValue: 1 << 1)
//}
//
//struct AllChatLayoutFilterType: OptionSet {
//    let rawValue: UInt
//    
//    static let people = AllChatLayoutFilterType(rawValue: 1 << 0)
//    static let rooms = AllChatLayoutFilterType(rawValue: 1 << 1)
//    static let favourites = AllChatLayoutFilterType(rawValue: 1 << 2)
//    static let unreads = AllChatLayoutFilterType(rawValue: 1 << 3)
//}
//
//enum AllChatLayoutSortingType: UInt {
//    case activity
//    case alphabetical
//}

// MARK: - Notification constants

extension AllChatsLayoutSettings {
    /// Posted if settings have changed
    public static let didUpdateFilters = Notification.Name("AllChatLayoutSettingsDidUpdateFilters")
}

@objcMembers
@objc class AllChatsLayoutSettings: NSObject, NSCoding {
    
    let sections: AllChatsLayoutSectionType
    let filters: AllChatsLayoutFilterType
    var activeFilters: AllChatsLayoutFilterType = [] {
        didSet {
            NotificationCenter.default.post(name: AllChatsLayoutSettings.didUpdateFilters, object: self)
        }
    }
    let sorting: AllChatsLayoutSortingType
    let pinnedSpaceIds: [String]
    var activePinnedSpaceId: String? {
        didSet {
            NotificationCenter.default.post(name: AllChatsLayoutSettings.didUpdateFilters, object: self)
        }
    }
    
    init(sections: AllChatsLayoutSectionType = [],
         filters: AllChatsLayoutFilterType = [],
         sorting: AllChatsLayoutSortingType = .activity,
         pinnedSpaceIds: [String] = []) {
        self.sections = sections
        self.filters = filters
        self.sorting = sorting
        self.pinnedSpaceIds = pinnedSpaceIds
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(Int64(sections.rawValue), forKey: "sections")
        coder.encode(Int64(filters.rawValue), forKey: "filters")
        coder.encode(Int64(activeFilters.rawValue), forKey: "activeFilters")
        coder.encode(Int64(sorting.rawValue), forKey: "sorting")
        coder.encode(pinnedSpaceIds, forKey: "pinnedSpaceIds")
        if let activePinnedSpaceId = activePinnedSpaceId {
            coder.encode(activePinnedSpaceId, forKey: "activePinnedSpaceId")
        }
    }
    
    required init?(coder: NSCoder) {
        self.sections = AllChatsLayoutSectionType(rawValue: UInt(coder.decodeInt64(forKey: "sections")))
        self.filters = AllChatsLayoutFilterType(rawValue: UInt(coder.decodeInt64(forKey: "filters")))
        self.activeFilters = AllChatsLayoutFilterType(rawValue: UInt(coder.decodeInt64(forKey: "activeFilters")))
        self.sorting = AllChatsLayoutSortingType(rawValue: UInt(coder.decodeInt64(forKey: "sorting"))) ?? .activity
        self.pinnedSpaceIds = coder.decodeObject(forKey: "pinnedSpaceIds") as? [String] ?? []
        self.activePinnedSpaceId = coder.decodeObject(forKey: "activePinnedSpaceId") as? String
    }
}
