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
