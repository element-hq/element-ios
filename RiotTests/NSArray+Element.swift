// 
// Copyright 2021 New Vector Ltd
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
