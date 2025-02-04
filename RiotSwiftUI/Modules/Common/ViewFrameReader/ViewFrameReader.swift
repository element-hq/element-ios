//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Used to calculate the frame of a view.
///
/// Useful in situations as with `ZStack` where you might want to layout views using alignment guides.
/// ```
/// @State private var frame: CGRect = CGRect.zero
/// ...
/// SomeView()
///    .background(ViewFrameReader(frame: $frame))
/// ```
struct ViewFrameReader: View {
    @Binding var frame: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: FramePreferenceKey.self,
                            value: geometry.frame(in: .local))
        }
        .onPreferenceChange(FramePreferenceKey.self) {
            frame = $0
        }
    }
}
