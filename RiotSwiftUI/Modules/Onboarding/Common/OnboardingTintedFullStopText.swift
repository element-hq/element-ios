//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
