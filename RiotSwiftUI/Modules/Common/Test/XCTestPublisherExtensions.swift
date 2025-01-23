//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

extension XCTestCase {
    /// XCTest utility to wait for results from publishers, so that the output can be used for assertions.
    ///
    ///  ```
    /// let collectedEvents = somePublisher.collect(3).first()
    /// XCTAssertEqual(try xcAwait(collectedEvents), [expected, values, here])
    ///  ```
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - timeout: A timeout after which we give up.
    /// - Throws: If it can't get the unwrapped result.
    /// - Returns: The unwrapped result.
    func xcAwait<T: Publisher>(_ publisher: T,
                               timeout: TimeInterval = 10) throws -> T.Output {
        try xcAwaitDeferred(publisher, timeout: timeout)()
    }
    
    /// XCTest utility that allows for a deferred wait of results from publishers, so that the output can be used for assertions.
    ///
    ///  ```
    /// let collectedEvents = somePublisher.collect(3).first()
    /// let awaitDeferred = xcAwaitDeferred(collectedEvents)
    /// // Do some other work that publishes to somePublisher
    /// XCTAssertEqual(try awaitDeferred(), [expected, values, here])
    ///  ```
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - timeout: A timeout after which we give up.
    /// - Returns: A closure that starts the waiting of results when called. The closure will return the unwrapped result.
    func xcAwaitDeferred<T: Publisher>(_ publisher: T,
                                       timeout: TimeInterval = 10) -> (() throws -> (T.Output)) {
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )
        return {
            self.waitForExpectations(timeout: timeout)
            cancellable.cancel()
            let unwrappedResult = try XCTUnwrap(
                result,
                "Awaited publisher did not produce any output"
            )
            return try unwrappedResult.get()
        }
    }
}
