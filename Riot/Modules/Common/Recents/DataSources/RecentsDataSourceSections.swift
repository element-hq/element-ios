// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/**
 Data structure representing the current arrangement of sections in a given data source,
 where a numerical session index (used for table views) is associated with its semantic
 value (e.g. "favorites" = 2).
 */
@objc class RecentsDataSourceSections: NSObject {
    typealias SectionIndex = Int
    static let MissingSectionIndex = -1
    
    @objc var count: Int {
        sections.count
    }
    
    @objc var sectionTypes: [NSNumber] {
        sections
            .sorted { $0.value < $1.value }
            .map { NSNumber(value: $0.key.rawValue) }
    }

    private var sections: [RecentsDataSourceSectionType: SectionIndex] = [:]
    
    init(sectionTypes: [RecentsDataSourceSectionType]) {
        sections = sectionTypes
            .enumerated()
            .reduce(into: [RecentsDataSourceSectionType: SectionIndex]()) { dict, item in
                dict[item.element] = item.offset
            }
    }
    
    // Objective-C cannot represent int-enums as an array, so a convenience function
    // allows passing them as a list of NSNumbers, that are internally extracted
    @objc convenience init(sectionTypes: [NSNumber]) {
        let types = sectionTypes.compactMap {
            RecentsDataSourceSectionType(rawValue: $0.intValue)
        }
        self.init(sectionTypes: types)
    }
    
    @objc func contains(_ sectionType: RecentsDataSourceSectionType) -> Bool {
        return sections.contains {
            $0.key == sectionType
        }
    }
    
    @objc func sectionIndex(forSectionType sectionType: RecentsDataSourceSectionType) -> SectionIndex {
        guard let index = sections[sectionType] else {
            // Objective-c code does not allow returning optional Int, so must use -1
            return Self.MissingSectionIndex
        }
        return index
    }
    
    @objc func sectionType(forSectionIndex sectionIndex: SectionIndex) -> RecentsDataSourceSectionType {
        guard let item = sections.first(where: { $0.value == sectionIndex }) else {
            // Objective-c code does not allow returning optional Int, so must use .unknown
            return .unknown
        }
        return item.key
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RecentsDataSourceSections else {
            return false
        }
        return sections == other.sections
    }
}
