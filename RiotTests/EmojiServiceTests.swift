/*
 Copyright 2019 New Vector Ltd
 
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
