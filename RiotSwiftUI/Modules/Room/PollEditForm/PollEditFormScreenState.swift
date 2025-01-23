//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockPollEditFormScreenState: MockScreenState, CaseIterable {
    case standard
    
    var screenType: Any.Type {
        PollEditForm.self
    }
    
    var screenView: ([Any], AnyView) {
        let viewModel = PollEditFormViewModel(parameters: PollEditFormViewModelParameters(mode: .creation, pollDetails: .default))
        return ([viewModel], AnyView(PollEditForm(viewModel: viewModel.context)))
    }
}
