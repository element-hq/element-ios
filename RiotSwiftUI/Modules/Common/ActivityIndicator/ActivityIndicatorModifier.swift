//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// A modifier for showing the activity indicator centered over a view.
struct ActivityIndicatorModifier: ViewModifier {
    var show: Bool
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .overlay(activityIndicator, alignment: .center)
    }
    
    @ViewBuilder
    private var activityIndicator: some View {
        if show {
            ActivityIndicator()
        }
    }
}

extension View {
    func activityIndicator(show: Bool) -> some View {
        modifier(ActivityIndicatorModifier(show: show))
    }
}
