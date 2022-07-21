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
@testable import Element

class URLPreviewStoreTests: XCTestCase {
    var store: URLPreviewStore!
    
    /// Creates mock URL preview data for matrix.org
    func matrixPreview() -> URLPreviewData {
        let preview = URLPreviewData(url: URL(string: "https://www.matrix.org/")!,
                                     eventID: "",
                                     roomID: "",
                                     siteName: "Matrix",
                                     title: "Home",
                                     text: "An open network for secure, decentralized communication")
        preview.image = Asset.Images.appSymbol.image
        
        return preview
    }
    
    /// Creates mock URL preview data for element.io
    func elementPreview() -> URLPreviewData {
        URLPreviewData(url: URL(string: "https://element.io/")!,
                       eventID: "",
                       roomID: "",
                       siteName: "Element",
                       title: "Home",
                       text: "Secure and independent communication, connected via Matrix")
    }
    
    
    /// Creates a fake `MXEvent` object to be passed to the store as needed.
    func fakeEvent() -> MXEvent {
        let event = MXEvent()
        event.eventId = ""
        event.roomId = ""
        return event
    }
    
    override func setUpWithError() throws {
        // Create a fresh in-memory cache for each test.
        store = URLPreviewStore(inMemory: true)
    }
    
    func testStoreAndRetrieve() {
        // Given a URL preview
        let preview = matrixPreview()
        
        // When caching and retrieving that preview.
        store.cache(preview)
        
        guard let cachedPreview = store.preview(for: preview.url, and: fakeEvent()) else {
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
        store.cache(preview)
        
        guard let cachedPreview = store.preview(for: preview.url, and: fakeEvent()) else {
            XCTFail("The cache should return a preview after storing one with the same URL.")
            return
        }
        XCTAssertEqual(cachedPreview.text, preview.text, "The text should match the original preview's text.")
        XCTAssertEqual(store.cacheCount(), 1, "There should be 1 item in the cache.")
        
        // When storing an updated version of that preview.
        let updatedPreview = URLPreviewData(url: preview.url,
                                            eventID: "",
                                            roomID: "",
                                            siteName: "Matrix",
                                            title: "Home",
                                            text: "We updated our website.")
        store.cache(updatedPreview)
        
        // Then the store should update the original preview.
        guard let updatedCachedPreview = store.preview(for: preview.url, and: fakeEvent()) else {
            XCTFail("The cache should return a preview after storing one with the same URL.")
            return
        }
        XCTAssertEqual(updatedCachedPreview.text, updatedPreview.text, "The text should match the updated preview's text.")
        XCTAssertEqual(store.cacheCount(), 1, "There should still only be 1 item in the cache.")
    }
    
    func testPreviewExpiry() {
        // Given a preview generated 30 days ago.
        let preview = matrixPreview()
        store.cache(preview, generatedOn: Date().addingTimeInterval(-60 * 60 * 24 * 30))
        
        // When retrieving that today.
        let cachedPreview = store.preview(for: preview.url, and: fakeEvent())
        
        // Then no preview should be returned.
        XCTAssertNil(cachedPreview, "The expired preview should not be returned.")
    }
    
    func testRemovingExpiredItems() {
        // Given a cache with 2 items, one of which has expired.
        testPreviewExpiry()
        let preview = elementPreview()
        store.cache(preview)
        XCTAssertEqual(store.cacheCount(), 2, "There should be 2 items in the cache.")
        
        // When removing expired items.
        store.removeExpiredItems()
        
        // Then only the expired item should have been removed.
        XCTAssertEqual(store.cacheCount(), 1, "Only 1 item should have been removed from the cache.")
        if store.preview(for: preview.url, and: fakeEvent()) == nil {
            XCTFail("The valid preview should still be in the cache.")
        }
    }
    
    func testClearingTheCache() {
        // Given a cache with 2 items.
        testStoreAndRetrieve()
        let preview = elementPreview()
        store.cache(preview)
        XCTAssertEqual(store.cacheCount(), 2, "There should be 2 items in the cache.")
        
        // When clearing the cache.
        store.deleteAll()
        
        // Then no items should be left in the cache
        XCTAssertEqual(store.cacheCount(), 0, "The cache should be empty.")
    }
}
