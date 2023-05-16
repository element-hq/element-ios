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

import SwiftUI

enum MockComposerLinkActionScreenState: MockScreenState, CaseIterable {
    case edit
    case createWithText
    case create
    
    var screenType: Any.Type {
        ComposerLinkAction.self
    }
    
    var screenView: ([Any], AnyView) {
        let viewModel: ComposerLinkActionViewModel
        switch self {
        case .createWithText:
            viewModel = .init(from: .createWithText)
        case .create:
            viewModel = .init(from: .create)
        case .edit:
            viewModel = .init(from: .edit(url: "https://element.io"))
        }
        return (
            [viewModel],
            AnyView(ComposerLinkAction(viewModel: viewModel.context))
        )
    }
}
