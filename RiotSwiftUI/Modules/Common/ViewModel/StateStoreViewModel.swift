//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

import Combine
import Foundation

/// A constrained and concise interface for interacting with the ViewModel.
///
/// This class is closely bound to`StateStoreViewModel`. It provides the exact interface the view should need to interact
/// ViewModel (as modelled on our previous template architecture with the addition of two-way binding):
/// - The ability read/observe view state
/// - The ability to send view events
/// - The ability to bind state to a specific portion of the view state safely.
/// This class was brought about a little bit by necessity. The most idiomatic way of interacting with SwiftUI is via `@Published`
/// properties which which are property wrappers and therefore can't be defined within protocols.
/// A similar approach is taken in libraries like [CombineFeedback](https://github.com/sergdort/CombineFeedback).
/// It provides a nice layer of consistency and also safety. As we are not passing the `ViewModel` to the view directly, shortcuts/hacks
/// can't be made into the `ViewModel`.
@dynamicMemberLookup
final class ViewModelContext<ViewState: BindableState, ViewAction>: ObservableObject {
    // MARK: - Properties

    // MARK: Private

    fileprivate let viewActions: PassthroughSubject<ViewAction, Never>

    // MARK: Public

    /// Get-able/Observable `Published` property for the `ViewState`
    @Published fileprivate(set) var viewState: ViewState

    /// Set-able/Bindable access to the bindable state.
    subscript<T>(dynamicMember keyPath: WritableKeyPath<ViewState.BindStateType, T>) -> T {
        get { viewState.bindings[keyPath: keyPath] }
        set { viewState.bindings[keyPath: keyPath] = newValue }
    }
    
    // MARK: Setup

    init(initialViewState: ViewState) {
        self.viewActions = PassthroughSubject()
        self.viewState = initialViewState
    }

    // MARK: Public

    /// Send a `ViewAction` to the `ViewModel` for processing.
    /// - Parameter viewAction: The `ViewAction` to send to the `ViewModel`.
    func send(viewAction: ViewAction) {
        viewActions.send(viewAction)
    }
}

/// A common ViewModel implementation for handling of `State`, `StateAction`s and `ViewAction`s
///
/// Generic type State is constrained to the BindableState protocol in that it may contain (but doesn't have to)
/// a specific portion of state that can be safely bound to.
/// If we decide to add more features to our state management (like doing state processing off the main thread)
/// we can do it in this centralised place.
class StateStoreViewModel<State: BindableState, ViewAction> {
    typealias Context = ViewModelContext<State, ViewAction>

    // MARK: - Properties

    // MARK: Public
    
    /// For storing subscription references.
    ///
    /// Left as public for `ViewModel` implementations convenience.
    var cancellables = Set<AnyCancellable>()

    /// Constrained interface for passing to Views.
    var context: Context
    
    var state: State {
        get { context.viewState }
        set { context.viewState = newValue }
    }
    
    // MARK: Setup

    init(initialViewState: State) {
        context = Context(initialViewState: initialViewState)
        context.viewActions.sink { [weak self] action in
            guard let self = self else { return }
            self.process(viewAction: action)
        }
        .store(in: &cancellables)
    }

    /// Override to handles incoming `ViewAction`s from the `ViewModel`.
    /// - Parameter viewAction: The `ViewAction` to be processed in `ViewModel` implementation.
    func process(viewAction: ViewAction) {
        // Default implementation, -no-op
    }
}
