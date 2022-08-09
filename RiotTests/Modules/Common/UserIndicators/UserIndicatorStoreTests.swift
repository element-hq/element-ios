// 
// Copyright 2022 New Vector Ltd
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
