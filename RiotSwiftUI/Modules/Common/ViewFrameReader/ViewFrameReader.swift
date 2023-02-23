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
