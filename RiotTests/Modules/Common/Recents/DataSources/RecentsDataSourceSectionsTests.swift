// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest
@testable import Element

class RecentsDataSourceSectionsTests: XCTestCase {
    func test_canCreateWithNSNumbers() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            NSNumber(value: -1),
            NSNumber(value: 0),
            NSNumber(value: 2),
            NSNumber(value: 100),
        ])
        
        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections.contains(.crossSigningBanner))
        XCTAssertTrue(sections.contains(.directory))
    }
    
    func test_hasCorrectCount() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            .invites,
            .favorites,
            .searchedRoom,
            .lowPriority,
            .serverNotice
        ])
        
        XCTAssertEqual(sections.count, 5)
    }
    
    func test_containsCorrectTypes() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .directory,
            .lowPriority,
            .serverNotice
        ])
        
        XCTAssertTrue(sections.contains(.favorites))
        XCTAssertTrue(sections.contains(.directory))
        XCTAssertTrue(sections.contains(.lowPriority))
        XCTAssertTrue(sections.contains(.serverNotice))
        
        XCTAssertFalse(sections.contains(.invites))
        XCTAssertFalse(sections.contains(.searchedRoom))
    }
    
    func test_hasCorrectSectionIndices() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            .invites,
            .favorites,
            .searchedRoom,
            .lowPriority
        ])
        
        XCTAssertEqual(sections.sectionIndex(forSectionType: .invites), 0)
        XCTAssertEqual(sections.sectionIndex(forSectionType: .favorites), 1)
        XCTAssertEqual(sections.sectionIndex(forSectionType: .searchedRoom), 2)
        XCTAssertEqual(sections.sectionIndex(forSectionType: .lowPriority), 3)
        
        XCTAssertEqual(sections.sectionIndex(forSectionType: .suggestedRooms), -1)
    }
    
    func test_indicesMatchCorrectTypes() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .invites,
            .lowPriority,
            .searchedRoom,
        ])
        
        XCTAssertEqual(sections.sectionType(forSectionIndex: 0), .favorites)
        XCTAssertEqual(sections.sectionType(forSectionIndex: 1), .invites)
        XCTAssertEqual(sections.sectionType(forSectionIndex: 2), .lowPriority)
        XCTAssertEqual(sections.sectionType(forSectionIndex: 3), .searchedRoom)
        
        XCTAssertEqual(sections.sectionType(forSectionIndex: -1), .unknown)
        XCTAssertEqual(sections.sectionType(forSectionIndex: 100), .unknown)
    }
    
    func test_returnsSectionTypesAsNSNumbers() {
        let sections = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .invites,
            .lowPriority,
            .searchedRoom,
        ])
        
        XCTAssertEqual(
            sections.sectionTypes,
            [
                NSNumber(value: RecentsDataSourceSectionType.favorites.rawValue),
                NSNumber(value: RecentsDataSourceSectionType.invites.rawValue),
                NSNumber(value: RecentsDataSourceSectionType.lowPriority.rawValue),
                NSNumber(value: RecentsDataSourceSectionType.searchedRoom.rawValue),
            ]
        )
    }
    
    func test_equalsIfSameSectionsInSameOrder() {
        let original = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .invites,
            .lowPriority,
            .searchedRoom,
        ])
        let sameOrder = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .invites,
            .lowPriority,
            .searchedRoom,
        ])
        let differentOrder = RecentsDataSourceSections(sectionTypes: [
            .lowPriority,
            .favorites,
            .invites,
            .searchedRoom,
        ])
        let differentSections = RecentsDataSourceSections(sectionTypes: [
            .favorites,
            .serverNotice,
            .lowPriority,
            .searchedRoom,
        ])
        
        XCTAssertEqual(original, sameOrder)
        XCTAssertNotEqual(original, differentOrder)
        XCTAssertNotEqual(original, differentSections)
    }
}
