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
@testable import Riot

class URLPreviewCacheTests: XCTestCase {
    var cache: URLPreviewCache!
    
    func matrixPreview() -> URLPreviewViewData {
        let preview = URLPreviewViewData(url: URL(string: "https://www.matrix.org/")!,
                                         siteName: "Matrix",
                                         title: "Home",
                                         text: "An open network for secure, decentralized communication")
        preview.image = Asset.Images.appSymbol.image
        
        return preview
    }
    
    func elementPreview() -> URLPreviewViewData {
        URLPreviewViewData(url: URL(string: "https://element.io/")!,
                           siteName: "Element",
                           title: "Home",
                           text: "Secure and independent communication, connected via Matrix")
    }
    
    override func setUpWithError() throws {
        // Create a fresh in-memory cache for each test.
        cache = URLPreviewCache(inMemory: true)
    }
    
    func testStoreAndRetrieve() {
        // Given a URL preview
        let preview = matrixPreview()
        
        // When storing and retrieving that preview.
        cache.store(preview)
        
        guard let cachedPreview = cache.preview(for: preview.url) else {
            XCTFail("The cache should return a preview after storing one with the same URL.")
            return
        }
        
        // Then the content in the retrieved preview should match the original preview.
        XCTAssertEqual(cachedPreview.url, preview.url, "The url should match.")
        XCTAssertEqual(cachedPreview.siteName, preview.siteName, "The site name should match.")
        XCTAssertEqual(cachedPreview.title, preview.title, "The title should match.")
        XCTAssertEqual(cachedPreview.text, preview.text, "The text should match.")
        XCTAssertEqual(cachedPreview.image == nil, preview.image == nil, "The cached preview should have an image if the original did.")
    }
    
    func testUpdating() {
        // Given a preview stored in the cache.
        let preview = matrixPreview()
        cache.store(preview)
        
        guard let cachedPreview = cache.preview(for: preview.url) else {
            XCTFail("The cache should return a preview after storing one with the same URL.")
            return
        }
        XCTAssertEqual(cachedPreview.text, preview.text, "The text should match the original preview's text.")
        XCTAssertEqual(cache.count(), 1, "There should be 1 item in the cache.")
        
        // When storing an updated version of that preview.
        let updatedPreview = URLPreviewViewData(url: preview.url, siteName: "Matrix", title: "Home", text: "We updated our website.")
        cache.store(updatedPreview)
        
        // Then the store should update the original preview.
        guard let updatedCachedPreview = cache.preview(for: preview.url) else {
            XCTFail("The cache should return a preview after storing one with the same URL.")
            return
        }
        XCTAssertEqual(updatedCachedPreview.text, updatedPreview.text, "The text should match the updated preview's text.")
        XCTAssertEqual(cache.count(), 1, "There should still only be 1 item in the cache.")
    }
    
    func testPreviewExpiry() {
        // Given a preview generated 30 days ago.
        let preview = matrixPreview()
        cache.store(preview, generatedOn: Date().addingTimeInterval(-60 * 60 * 24 * 30))
        
        // When retrieving that today.
        let cachedPreview = cache.preview(for: preview.url)
        
        // Then no preview should be returned.
        XCTAssertNil(cachedPreview, "The expired preview should not be returned.")
    }
    
    func testRemovingExpiredItems() {
        // Given a cache with 2 items, one of which has expired.
        testPreviewExpiry()
        let preview = elementPreview()
        cache.store(preview)
        XCTAssertEqual(cache.count(), 2, "There should be 2 items in the cache.")
        
        // When removing expired items.
        cache.removeExpiredItems()
        
        // Then only the expired item should have been removed.
        XCTAssertEqual(cache.count(), 1, "Only 1 item should have been removed from the cache.")
        if cache.preview(for: preview.url) == nil {
            XCTFail("The valid preview should still be in the cache.")
        }
    }
    
    func testClearingTheCache() {
        // Given a cache with 2 items.
        testStoreAndRetrieve()
        let preview = elementPreview()
        cache.store(preview)
        XCTAssertEqual(cache.count(), 2, "There should be 2 items in the cache.")
        
        // When clearing the cache.
        cache.clear()
        
        // Then no items should be left in the cache
        XCTAssertEqual(cache.count(), 0, "The cache should be empty.")
    }
}
