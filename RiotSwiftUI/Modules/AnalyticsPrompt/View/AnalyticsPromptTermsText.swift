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
    
    // MARK: Public
    
    let promptType: AnalyticsPromptType
    
    // MARK: Views
    
    var body: some View {
        let (start, link, end) = promptType.termsStrings
        
        Text(start)
            + Text(link).foregroundColor(theme.colors.accent)
            + Text(end)
    }
}
