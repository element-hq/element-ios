//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
