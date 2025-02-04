//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

@available(iOS, introduced: 14.0, deprecated: 15.0, message: "Use Text with an AttributedString instead that includes a link and handle the tap by adding an OpenURLAction to the environment.")
/// A `Button`, that fakes having a tappable string inside of a regular string.
struct InlineTextButton: View {
    private struct StringComponent {
        let string: Substring
        let isTinted: Bool
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    /// The individual components of the string.
    private let components: [StringComponent]
    private let action: () -> Void

    // MARK: - Setup
    
    /// Creates a new `InlineTextButton`.
    /// - Parameters:
    ///   - mainText: The main text that shouldn't appear tappable. This must contain a single `%@` placeholder somewhere within.
    ///   - tappableText: The tappable text that will be substituted into the `%@` placeholder.
    ///   - action: The action to perform when tapping the button.
    ///   - alwaysCallAction: If true calls the action on tap action even if the `tappableText` isn't found inside the `mainText`
    init(_ mainText: String, tappableText: String, alwaysCallAction: Bool = true, action: @escaping () -> Void) {
        guard let range = mainText.range(of: "%@") else {
            components = [StringComponent(string: Substring(mainText), isTinted: false)]
            self.action = alwaysCallAction ? action : { }
            return
        }
        
        let firstComponent = StringComponent(string: mainText[..<range.lowerBound], isTinted: false)
        let middleComponent = StringComponent(string: Substring(tappableText), isTinted: true)
        let lastComponent = StringComponent(string: mainText[range.upperBound...], isTinted: false)
        
        components = [firstComponent, middleComponent, lastComponent]
        self.action = action
    }
    
    // MARK: - Views
    
    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(Style(components: components))
        .accessibilityLabel(components.map(\.string).joined())
    }
    
    private struct Style: ButtonStyle {
        let components: [StringComponent]
        
        func makeBody(configuration: Configuration) -> some View {
            components.reduce(Text("")) { lastValue, component in
                var text: Text = .init(component.string)
                
                if component.isTinted {
                    text = text.foregroundColor(.accentColor.opacity(configuration.isPressed ? 0.2 : 1))
                }
                
                return lastValue + text
            }
        }
    }
}

struct Previews_InlineButtonText_Previews: PreviewProvider {
    static var previews: some View {
        InlineTextButton("Hello there this is a sentence. %@.",
                         tappableText: "And this is a button",
                         action: { })
            .padding()
    }
}
