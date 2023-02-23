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

/// A view that displays text, highlighting the first occurrence of
/// the character `.` in the theme's accent color.
struct OnboardingTintedFullStopText: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme
    
    private struct StringComponent {
        let string: Substring
        let isColored: Bool
    }
    
    /// The individual components of the string.
    private let components: [StringComponent]
    
    // MARK: - Setup
    
    init(_ text: String) {
        guard let range = text.range(of: ".") else {
            components = [StringComponent(string: Substring(text), isColored: false)]
            return
        }
        
        let firstComponent = StringComponent(string: text[..<range.lowerBound], isColored: false)
        let middleComponent = StringComponent(string: text[range], isColored: true)
        let lastComponent = StringComponent(string: text[range.upperBound...], isColored: false)
        
        components = [firstComponent, middleComponent, lastComponent]
    }
    
    // MARK: - Views
    
    var body: some View {
        components.reduce(Text("")) { lastValue, component in
            lastValue + Text(component.string)
                .foregroundColor(component.isColored ? theme.colors.accent : nil)
        }
    }
}
