//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Introspect
import SwiftUI

/// Introspects the view to find a table view on iOS 14/15 or a collection view
/// on iOS 16 and sets the background to the specified color.
struct ListBackgroundModifier: ViewModifier {
    /// The background color.
    let color: Color
    
    func body(content: Content) -> some View {
        // When using Xcode 13
        #if compiler(<5.7)
        // SwiftUI's List is backed by a table view.
        content.introspectTableView { $0.backgroundColor = UIColor(color) }
        
        // When using Xcode 14+
        #else
        if #available(iOS 16, *) {
            // SwiftUI's List is backed by a collection view on iOS 16.
            content
                .introspectCollectionView { $0.backgroundColor = UIColor(color) }
                .scrollContentBackground(.hidden)
        } else {
            // SwiftUI's List is backed by a table view on iOS 15 and below.
            content.introspectTableView { $0.backgroundColor = UIColor(color) }
        }
        #endif
    }
}

extension View {
    /// Sets the background color of a `List` using introspection.
    func listBackgroundColor(_ color: Color) -> some View {
        modifier(ListBackgroundModifier(color: color))
    }
}
