//
// Copyright 2022 New Vector Ltd
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
    
    /// Finds a `UICollectionView` from a `SwiftUI.List`, or `SwiftUI.List` child.
    /// Stop gap until https://github.com/siteline/SwiftUI-Introspect/pull/169
    func introspectCollectionView(customize: @escaping (UICollectionView) -> Void) -> some View {
        introspect(selector: TargetViewSelector.ancestorOrSiblingContaining, customize: customize)
    }
}
