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

struct OnboardingSplashScreenPageIndicator: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme
    
    // MARK: Public

    /// The number of pages that are shown.
    let pageCount: Int
    /// The index of the current page
    let pageIndex: Int
    
    // MARK: - Setup
    
    internal init(pageCount: Int, pageIndex: Int) {
        self.pageCount = pageCount
        
        // Clamp the page index to handle the hidden page.
        if pageIndex == -1 {
            self.pageIndex = pageCount - 1
        } else {
            self.pageIndex = pageIndex % pageCount
        }
    }
    
    var body: some View {
        HStack {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(index == pageIndex ? .accentColor : theme.colors.quarterlyContent)
            }
        }
    }
}
