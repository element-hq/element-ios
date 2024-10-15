/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
