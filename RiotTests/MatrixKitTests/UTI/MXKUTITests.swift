/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
