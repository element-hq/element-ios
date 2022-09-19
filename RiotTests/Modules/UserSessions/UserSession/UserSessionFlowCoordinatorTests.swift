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

import XCTest
@testable import Element

class UserSessionFlowCoordinatorTests: XCTestCase {
    
    func test_start_shouldPushView() throws {
        let userSessionInfo = UserSessionInfo(sessionId: "session", sessionName: "iOS", deviceType: .mobile, isVerified: false, lastSeenIP: "10.0.0.10", lastSeenTimestamp: Date().timeIntervalSince1970)
        let navigationRouterSpy = NavigationRouterSpy()
        let params = UserSessionFlowCoordinatorParameters(session:  MXSession(),
                                                          navigationRouter: navigationRouterSpy,
                                                          userSessionInfo: userSessionInfo)
        let sut = UserSessionFlowCoordinator(parameters: params)
        sut.start()
        XCTAssertNotNil(navigationRouterSpy.modulePushed)
    }
}

private class NavigationRouterSpy: NavigationRouterType {
    
    var modules: [Presentable] = []
    var modulePushed: Presentable?
    
    func present(_ module: Presentable, animated: Bool) {
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
    }
    
    func setRootModule(_ module: Presentable, hideNavigationBar: Bool, animated: Bool, popCompletion: (() -> Void)?) {
    }
    
    func setModules(_ modules: [NavigationModule], hideNavigationBar: Bool, animated: Bool) {
    }
    
    func popToRootModule(animated: Bool) {
    }
    
    func popToModule(_ module: Presentable, animated: Bool) {
    }
    
    func popModule(animated: Bool) {
    }
    
    func push(_ module: Presentable, animated: Bool, popCompletion: (() -> Void)?) {
        modulePushed = module
    }
    
    func push(_ modules: [NavigationModule], animated: Bool) {
    }
    
    func popAllModules(animated: Bool) {
    }
    
    func contains(_ module: Presentable) -> Bool {
        false
    }
    
    func toPresentable() -> UIViewController {
        UIViewController()
    }
}
