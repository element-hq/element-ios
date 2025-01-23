//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Positions this view within an invisible frame that fills the width of its parent view,
/// whilst limiting the width of the content to a readable size (which is customizable).
private struct ReadableFrameModifier: ViewModifier {
    var maxWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Positions this view within an invisible frame that fills the width of its parent view,
    /// whilst limiting the width of the content to a readable size (which is customizable).
    func readableFrame(maxWidth: CGFloat = 600) -> some View {
        modifier(ReadableFrameModifier(maxWidth: maxWidth))
    }
}
