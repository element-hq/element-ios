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
        let depsAndViews  = screenStates.map(\.screenView)
        let deps = depsAndViews.map({ $0.0 })
        let views = depsAndViews.map({ $0.1 })
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
        screenStates.map { $0.title }
    }
    
    /// A title to represent the screen and it's screen state
    var title: String {
        "\(simpleTypeName(screenType.self)): \(simpleTypeName(self))"
    }
    
    private func simpleTypeName(_ type: Any) -> String {
        String(describing: type).components(separatedBy: .punctuationCharacters).filter { $0.count > 0}.last!
    }
}

extension MockScreenState where Self: CaseIterable {
    static var screenStates: [MockScreenState] {
        return Array(self.allCases)
    }
}
