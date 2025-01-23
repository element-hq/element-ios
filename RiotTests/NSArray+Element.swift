// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

class NSArray_Element: XCTestCase {
    
    var array: NSArray = NSArray()  //  will contain strings

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        array = NSArray(array: ["str 1", "string 2", "test string 3"])
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMap() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let mapped = array.vc_map { obj in
            guard let string = obj as? String else {
                XCTFail("Failed to setup test conditions")
                return -1
            }
            return string.count
        }
        
        XCTAssertEqual(array.count, mapped.count, "Every element in the array must be mapped")
        XCTAssertTrue(mapped.allSatisfy({ $0 is Int }), "Every element must be an Int")
        XCTAssertTrue(mapped.allSatisfy({ ($0 as? Int ?? 0) > 0 }), "Every element must be an Int, greater than zero")
    }
    
    func testCompactMap() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let nilMapped: [Any] = array.vc_compactMap { obj in
            return nil
        }
        XCTAssertTrue(nilMapped.isEmpty, "Mapped array must be empty")
        
        let onlyOneNilMapped: [Any] = array.vc_compactMap { obj in
            guard let string = obj as? String else {
                XCTFail("Failed to setup test conditions")
                return -1
            }
            if string.hasSuffix("2") {
                return nil
            }
            return string.count
        }
        
        XCTAssertEqual(array.count - 1, onlyOneNilMapped.count, "Every element in the array must be mapped, except 'string 2'")
        XCTAssertTrue(onlyOneNilMapped.allSatisfy({ $0 is Int }), "Every element must be an Int")
        XCTAssertTrue(onlyOneNilMapped.allSatisfy({ ($0 as? Int ?? 0) > 0 }), "Every element must be an Int, greater than zero")
    }
    
    func testFlatMap() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let emptyMapped: [Any] = array.vc_flatMap { obj in
            return []
        }
        XCTAssertTrue(emptyMapped.isEmpty, "Mapped array must be empty")
        
        let twiceMapped: [Any] = array.vc_flatMap { obj in
            guard let string = obj as? String else {
                XCTFail("Failed to setup test conditions")
                return []
            }
            return [string.count, string.count * 2]
        }
        XCTAssertEqual(array.count * 2, twiceMapped.count, "Mapped array must have twice time elements than the 'array'")
        
        let constantMapped: [Any] = array.vc_flatMap { obj in
            return [1, 2]
        }
        XCTAssertEqual(array.count * 2, constantMapped.count, "Constantly mapped array must still have twice time elements than the 'array'")
    }

}
