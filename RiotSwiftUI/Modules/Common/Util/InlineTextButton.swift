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
    internal init(_ mainText: String, tappableText: String, action: @escaping () -> Void) {
        guard let range = mainText.range(of: "%@") else {
            self.components = [StringComponent(string: Substring(mainText), isTinted: false)]
            self.action = action
            return
        }
        
        let firstComponent = StringComponent(string: mainText[..<range.lowerBound], isTinted: false)
        let middleComponent = StringComponent(string: Substring(tappableText), isTinted: true)
        let lastComponent = StringComponent(string: mainText[range.upperBound...], isTinted: false)
        
        self.components = [firstComponent, middleComponent, lastComponent]
        self.action = action
    }
    
    // MARK: - Views
    
    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(Style(components: components))
        .accessibilityLabel(components.map { $0.string }.joined())
    }
    
    private struct Style: ButtonStyle {
        let components: [StringComponent]
        
        func makeBody(configuration: Configuration) -> some View {
            components.reduce(Text("")) { lastValue, component in
                lastValue + Text(component.string)
                    .foregroundColor(component.isTinted ? .accentColor.opacity(configuration.isPressed ? 0.2 : 1) : nil)
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
