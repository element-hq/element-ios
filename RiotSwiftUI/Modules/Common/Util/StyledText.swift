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

import DesignKit
import SwiftUI

@available(iOS, introduced: 14.0, deprecated: 15.0, message: "Use Text with an AttributedString instead.")
/// A `Text` view that renders attributed strings with their `.font` and `.foregroundColor` attributes.
/// This view is a workaround for iOS 13/14 not supporting `AttributedString`.
struct StyledText: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    /// A string with a bold property.
    private struct StringComponent {
        let string: String
        var font: Font?
        var color: Color?
    }
    
    /// Internal representation of the string as composable parts.
    private let components: [StringComponent]
    
    // MARK: - Setup
    
    /// Creates a `StyledText` using the supplied attributed string.
    /// - Parameter attributedString: The attributed string to display.
    init(_ attributedString: NSAttributedString) {
        var components = [StringComponent]()
        let range = NSRange(location: 0, length: attributedString.length)
        let string = attributedString.string as NSString
        
        attributedString.enumerateAttributes(in: range, options: []) { attributes, range, _ in
            let font = attributes[.font] as? UIFont
            let color = attributes[.foregroundColor] as? UIColor
            
            let component = StringComponent(
                string: string.substring(with: range),
                font: font.map { Font($0) },
                color: color.map { Color($0) }
            )
            
            components.append(component)
        }
        
        self.components = components
    }
    
    /// Creates a `StyledText` using a plain string.
    /// - Parameter string: The plain string to display
    init(_ string: String) {
        components = [StringComponent(string: string, font: nil)]
    }
    
    // MARK: - Views
    
    var body: some View {
        components.reduce(Text("")) { lastValue, component in
            lastValue + Text(component.string)
                .font(component.font)
                .foregroundColor(component.color)
        }
    }
}

struct StyledText_Previews: PreviewProvider {
    static func prettyText() -> NSAttributedString {
        let string = NSMutableAttributedString(string: "T", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.red
        ])
        string.append(NSAttributedString(string: "e", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.orange
        ]))
        string.append(NSAttributedString(string: "s", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.yellow
        ]))
        string.append(NSAttributedString(string: "t", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 15),
            .foregroundColor: UIColor.green
        ]))
        string.append(NSAttributedString(string: "i", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.cyan
        ]))
        string.append(NSAttributedString(string: "n", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.blue
        ]))
        string.append(NSAttributedString(string: "g", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.purple
        ]))
        return string
    }
    
    static var previews: some View {
        VStack(spacing: 8) {
            StyledText("Hello, World!")
            StyledText(NSAttributedString(string: "Testing",
                                          attributes: [.font: UIFont.boldSystemFont(ofSize: 64)]))
            StyledText(prettyText())
        }
    }
}
