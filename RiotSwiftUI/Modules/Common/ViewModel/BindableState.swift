//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a specific portion of the ViewState that can be bound to with SwiftUI's [2-way binding](https://developer.apple.com/documentation/swiftui/binding).
protocol BindableState {
    /// The associated type of the Bindable State. Defaults to Void.
    associatedtype BindStateType = Void
    var bindings: BindStateType { get set }
}

extension BindableState where BindStateType == Void {
    /// We provide a default implementation for the Void type so that we can have `ViewState` that
    /// just doesn't include/take advantage of the bindings.
    var bindings: Void {
        get {
            ()
        }
        set {
            fatalError("Can't bind to the default Void binding.")
        }
    }
}
