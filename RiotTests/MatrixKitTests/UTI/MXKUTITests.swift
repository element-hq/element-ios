/*
 Copyright 2019 The Matrix.org Foundation C.I.C
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import XCTest

@testable import Element

import MobileCoreServices

class MXKUTITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUTIFromMimeType() {
        guard let uti = MXKUTI(mimeType: "application/pdf") else {
            XCTFail("uti should not be nil")
            return
        }
        
        let fileExtension = uti.fileExtension?.lowercased() ?? ""
        
        XCTAssertTrue(uti.isFile)
        XCTAssertEqual(fileExtension, "pdf")
    }
    
    func testUTIFromFileExtension() {
        let uti = MXKUTI(fileExtension: "pdf")
        
        let fileExtension = uti.fileExtension?.lowercased() ?? ""
        let mimeType = uti.mimeType ?? ""
        
        XCTAssertTrue(uti.isFile)
        XCTAssertEqual(fileExtension, "pdf")
        XCTAssertEqual(mimeType, "application/pdf")
    }
    
    func testUTIFromLocalFileURLLoadingResourceValues() {
        
        let bundle = Bundle(for: type(of: self))
        
        guard let localFileURL = bundle.url(forResource: "Text", withExtension: "txt") else {
            XCTFail("localFileURL should not be nil")
            return
        }
        
        guard let uti = MXKUTI(localFileURL: localFileURL) else {
            XCTFail("uti should not be nil")
            return
        }
        
        let fileExtension = uti.fileExtension?.lowercased() ?? ""
        let mimeType = uti.mimeType ?? ""
        
        XCTAssertTrue(uti.isFile)
        XCTAssertEqual(fileExtension, "txt")
        XCTAssertEqual(mimeType, "text/plain")
    }
    
    func testUTIFromLocalFileURL() {
        
        let bundle = Bundle(for: type(of: self))
        
        guard let localFileURL = bundle.url(forResource: "Text", withExtension: "txt") else {
            XCTFail("localFileURL should not be nil")
            return
        }
        
        guard let uti = MXKUTI(localFileURL: localFileURL, loadResourceValues: false) else {
            XCTFail("uti should not be nil")
            return
        }
        
        let fileExtension = uti.fileExtension?.lowercased() ?? ""
        let mimeType = uti.mimeType ?? ""
        
        XCTAssertTrue(uti.isFile)
        XCTAssertEqual(fileExtension, "txt")
        XCTAssertEqual(mimeType, "text/plain")
    }
}
