//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
