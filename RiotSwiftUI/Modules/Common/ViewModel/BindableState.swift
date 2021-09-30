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
