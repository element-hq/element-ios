/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import XCTest

@testable import Element

class EmojiServiceTests: XCTestCase {
    
    // MARK: - Constants
    
    private let defaultTimeout: TimeInterval = 10
    
    enum ExpectedEmojiCategory: Int {
        case people
        case nature
        case foods
        case activity
        case places
        case objects
        case symbols
        case flags
        
        var identifier: String {
            let identifier: String
            switch self {
            case .people:
                identifier = "people"
            case .nature:
                identifier = "nature"
            case .foods:
                identifier = "foods"
            case .activity:
                identifier = "activity"
            case .places:
                identifier = "places"
            case .objects:
                identifier = "objects"
            case .symbols:
                identifier = "symbols"
            case .flags:
                identifier = "flags"
            }
            return identifier
        }
        
        var emojisCount: Int {
            let emojiCount: Int
            switch self {
            case .people:
                emojiCount = 483
            case .nature:
                emojiCount = 127
            case .foods:
                emojiCount = 121
            case .activity:
                emojiCount = 79
            case .places:
                emojiCount = 210
            case .objects:
                emojiCount = 233
            case .symbols:
                emojiCount = 214
            case .flags:
                emojiCount = 267
            }
            return emojiCount
        }
        
        static var all: [ExpectedEmojiCategory] {
            return [
                .people, .nature, .foods, .activity, .places, .objects, .symbols, .flags
            ]
        }
    }
    
    // MARK: - Life cycle
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests
    
    func testEmojiService() {
        
        let expectation = self.expectation(description: "get Emoji categories")
        
        let emojiService = EmojiMartService()
        emojiService.getEmojiCategories { (response) in
            switch response {
            case .success(let emojiCategories):
                
                XCTAssertEqual(emojiCategories.count, ExpectedEmojiCategory.all.count)
                
                var index = 0
                for emojiCategory in emojiCategories {
                    guard let expectedEmojiCategory = ExpectedEmojiCategory(rawValue: index) else {
                        XCTFail("Fail to retrieve expected emoji category")
                        return
                    }
                    XCTAssertEqual(emojiCategory.identifier, expectedEmojiCategory.identifier)
                    XCTAssertEqual(emojiCategory.emojis.count, expectedEmojiCategory.emojisCount)
                    index+=1
                }
                
                let peopleEmojiCategory = emojiCategories[ExpectedEmojiCategory.people.rawValue]
                
                let grinningEmoji = peopleEmojiCategory.emojis[0]
                
                XCTAssertEqual(grinningEmoji.shortName, "grinning")
                XCTAssertEqual(grinningEmoji.value, "😀")
                XCTAssertEqual(grinningEmoji.keywords.count, 6)
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Fail with error: \(error)")
            }
        }
        
        self.waitForExpectations(timeout: self.defaultTimeout) {error in
            XCTAssertNil(error)
        }
    }
}
