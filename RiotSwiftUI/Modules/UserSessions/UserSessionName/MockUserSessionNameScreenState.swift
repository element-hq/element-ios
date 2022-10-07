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

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockUserSessionNameScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case initialName
    case empty
    case changedName
    
    /// The associated screen
    var screenType: Any.Type {
        UserSessionName.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: UserSessionNameViewModel
        switch self {
        case .initialName:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone)
        case .empty:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone)
            viewModel.state.bindings.sessionName = ""
        case .changedName:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone)
            viewModel.state.bindings.sessionName = "iPhone SE"
        }
        
        return ([viewModel], AnyView(UserSessionName(viewModel: viewModel.context)))
    }
}
