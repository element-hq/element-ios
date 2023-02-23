/*
 Copyright 2021 New Vector Ltd

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

class EmojiStoreTests: XCTestCase {

    func testFinds💯WhenSearchingForHundred() {
        find("hundred", expect: "💯")
    }

    func testFinds💯WhenSearchingFor100() {
        find("100", expect: "💯")
    }

    func testFinds2️⃣WhenSearchingForTwo() {
        find("two", expect: "2️⃣")
    }

    func testFinds2️⃣WhenSearchingFor2() {
        find("2", expect: "2️⃣")
    }
    
    // MARK: - Private
    
    private func find(_ searchText: String, expect emoji: String) {
        loadEmojiStore { emojiStore in
            let emojis = emojiStore.findEmojiItemsSortedByCategory(with: searchText).flatMap { $0.emojis.map { $0.value } }
            XCTAssert(emojis.contains(emoji), "Search text \"\(searchText)\" should find \"\(emoji)\" but only found \(emojis)")
        }
    }
    
    private func loadEmojiStore(_ completion: @escaping (EmojiStore) -> Void) {
        EmojiMartService().getEmojiCategories { response in
            switch response {
            case .success(let categories):
                let store = EmojiStore()
                store.set(categories)
                completion(store)
            case .failure(let error):
                XCTFail("Failed to load emojis: \(error)")
            }
        }
    }
}
