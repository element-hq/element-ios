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

struct AnalyticsPromptCheckmarkItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    /// A string with a bold property.
    private struct StringComponent {
        let string: String
        let isBold: Bool
    }
    
    /// Internal representation of the string as composable parts.
    private let components: [StringComponent]
    
    // MARK: - Setup
    
    init(attributedString: NSAttributedString) {
        var components = [StringComponent]()
        let range = NSRange(location: 0, length: attributedString.length)
        let string = attributedString.string as NSString
        
        attributedString.enumerateAttributes(in: range, options: []) { attributes, range, _ in
            var isBold = false
            
            if let font = attributes[.font] as? UIFont {
                isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
            }
            
            components.append(StringComponent(string: string.substring(with: range), isBold: isBold))
        }
        
        self.components = components
    }
    
    init(string: String) {
        components = [StringComponent(string: string, isBold: false)]
    }
    
    // MARK: - Views
    
    var label: Text {
        components.reduce(Text("")) {
            $0 + Text($1.string).font($1.isBold ? theme.fonts.bodySB : theme.fonts.body)
        }
    }
    
    var body: some View {
        Label { label } icon: {
            Image(uiImage: Asset.Images.analyticsCheckmark.image)
        }
    }
}

// MARK: - Previews

struct AnalyticsPromptCheckmarkItem_Previews: PreviewProvider {
    static let strings = MockAnalyticsPromptStrings()
    
    static var previews: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptCheckmarkItem(attributedString: strings.point1)
            AnalyticsPromptCheckmarkItem(attributedString: strings.point2)
            AnalyticsPromptCheckmarkItem(attributedString: strings.longString)
            AnalyticsPromptCheckmarkItem(attributedString: strings.shortString)
        }
        .padding()
    }
}
