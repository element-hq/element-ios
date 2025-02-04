//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Used for mocking top level screens and their various states.
protocol MockScreenState {
    static var screenStates: [MockScreenState] { get }
    var screenType: Any.Type { get }
    var screenView: ([Any], AnyView) { get }
}

extension MockScreenState {
    /// Get a list of the screens for every screen state.
    static var stateRenderer: StateRenderer {
        let depsAndViews = screenStates.map(\.screenView)
        let deps = depsAndViews.map(\.0)
        let views = depsAndViews.map(\.1)
        let titles = screenStates.map(\.title)
        
        var states = [ScreenStateInfo]()
        for i in 0..<deps.count {
            let dep = deps[i]
            let view = views[i]
            let screenTitle = titles[i]
            states.append(ScreenStateInfo(dependencies: dep, view: view, screenTitle: screenTitle))
        }
        
        return StateRenderer(states: states)
    }
    
    /// All available screen state keys
    static var screenNames: [String] {
        screenStates.map(\.title)
    }
    
    /// A title to represent the screen and it's screen state
    var title: String {
        "\(simpleTypeName(screenType.self)): \(simpleTypeName(self))"
    }
    
    private func simpleTypeName(_ type: Any) -> String {
        String(describing: type).components(separatedBy: .punctuationCharacters).filter { $0.count > 0 }.last!
    }
}

extension MockScreenState where Self: CaseIterable {
    static var screenStates: [MockScreenState] {
        Array(allCases)
    }
}
