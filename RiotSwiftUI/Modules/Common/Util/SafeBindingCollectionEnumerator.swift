//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/**
 Used to avoid crashes when enumerating through bindings in the AnswerOptions ForEach
 https://stackoverflow.com/q/65375372
 Replace with Swift 5.5 bindings enumerator later.
 */
struct SafeBindingCollectionEnumerator<T: RandomAccessCollection & MutableCollection, C: View>: View {
    typealias BoundElement = Binding<T.Element>
    private let binding: BoundElement
    private let content: (BoundElement) -> C
    
    init(_ binding: Binding<T>, index: T.Index, @ViewBuilder content: @escaping (BoundElement) -> C) {
        self.content = content
        self.binding = .init(get: { binding.wrappedValue[index] },
                             set: { binding.wrappedValue[index] = $0 })
    }
    
    var body: some View {
        content(binding)
    }
}
