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

@available(iOS 14.0, *)
/// The last line of text in the description with highlighting on the link string.
struct AnalyticsPromptTermsText: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    /// A string with a link attribute.
    private struct StringComponent {
        let string: String
        let isLink: Bool
    }
    
    /// Internal representation of the string as composable parts.
    private let components: [StringComponent]
    
    // MARK: - Setup
    
    init(attributedString: NSAttributedString) {
        var components = [StringComponent]()
        let range = NSRange(location: 0, length: attributedString.length)
        let string = attributedString.string as NSString
        
        attributedString.enumerateAttributes(in: range, options: []) { attributes, range, stop in
            let isLink = attributes.keys.contains(.link)
            components.append(StringComponent(string: string.substring(with: range), isLink: isLink))
        }
        
        self.components = components
    }
    
    // MARK: - Views
    
    var body: some View {
        components.reduce(Text("")) {
            $0 + Text($1.string).foregroundColor($1.isLink ? theme.colors.accent : nil)
        }
    }
}

// MARK: - Previews
@available(iOS 14.0, *)
struct AnalyticsPromptTermsText_Previews: PreviewProvider {
    
    static let strings = MockAnalyticsPromptStrings()
    
    static var previews: some View {
        VStack(spacing: 8) {
            AnalyticsPromptTermsText(attributedString: strings.termsNewUser)
            AnalyticsPromptTermsText(attributedString: strings.termsUpgrade)
        }
    }
}
