// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest
@testable import CommonKit
@testable import Element
import MatrixSDK

class UserIndicatorStoreTests: XCTestCase {
    class PresenterSpy: UserIndicatorTypePresenterProtocol {
        class ViewPresenter: UserIndicatorViewPresentable {
            func present() {}
            func dismiss() {}
        }
        
        var queue = UserIndicatorQueue()
        var indicators = [UserIndicator]()
        
        func present(_ type: UserIndicatorType) -> UserIndicator {
            let request = UserIndicatorRequest(presenter: ViewPresenter(), dismissal: .manual)
            let indicator = queue.add(request)
            indicators.append(indicator)
            return indicator
        }
    }
    
    private var presenter: PresenterSpy!
    private var store: UserIndicatorStore!
    
    override func setUp() {
        presenter = PresenterSpy()
        store = UserIndicatorStore(presenter: presenter)
    }
    
    func test_presentWillStartIndicator() {
        let _ = presentLoading()
        XCTAssertEqual(indicator(at: 0)?.state, .executing)
    }
    
    func test_cancelWillCompleteIndicator() {
        let cancel = presentLoading()
        
        cancel()
        
        XCTAssertEqual(indicator(at: 0)?.state, .completed)
    }
    
    func test_cancelWillStartNextIndicator() {
        let cancel = presentLoading()
        let _ = presentLoading()
        
        cancel()
        
        XCTAssertEqual(indicator(at: 1)?.state, .executing)
    }
    
    // MARK: - Helpers
    
    private func presentLoading() -> UserIndicatorCancel {
        return store.present(type: .loading(label: "xyz", isInteractionBlocking: false))
    }
    
    private func indicator(at index: Int) -> UserIndicator? {
        guard index < presenter.indicators.count else {
            return nil
        }
        return presenter.indicators[index]
    }
}
