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
import Combine

import Foundation
import Combine

protocol BindableState {
    associatedtype BindStateType = Void
    var bindings: BindStateType { get set }
}

extension BindableState where BindStateType == Void {
    var bindings: Void {
        get {
            ()
        }
        set {
            fatalError("Can't bind to the default Void binding.")
        }
    }
}

@available(iOS 14, *)
class ViewModelContext<ViewState:BindableState, ViewAction>: ObservableObject {
   
    private var cancellables = Set<AnyCancellable>()
    fileprivate let viewActions: PassthroughSubject<ViewAction, Never>
    
    @Published var bindings: ViewState.BindStateType
    @Published fileprivate(set) var viewState: ViewState

    init(initialViewState: ViewState) {
        self.bindings = initialViewState.bindings
        self.viewActions = PassthroughSubject()
        self.viewState = initialViewState
        if !(initialViewState.bindings is Void) {
            self.$bindings
                .weakAssign(to: \.viewState.bindings, on: self)
                .store(in: &cancellables)
        }
    }
    
    func send(viewAction: ViewAction) {
        viewActions.send(viewAction)
    }
}

@available(iOS 14, *)
class StateStoreViewModel<State:BindableState, StateAction, ViewAction> {
    
    typealias Context = ViewModelContext<State, ViewAction>
    
    let state: CurrentValueSubject<State, Never>

    var cancellables = Set<AnyCancellable>()
    var context: Context
    
    init(initialViewState: State) {
        
        self.context = Context(initialViewState: initialViewState)
        self.state = CurrentValueSubject(initialViewState)
        self.state.weakAssign(to: \.context.viewState, on: self)
            .store(in: &cancellables)
        self.context.viewActions.sink { [weak self] action in
            guard let self = self else { return }
            self.process(viewAction: action)
        }
        .store(in: &cancellables)
    }
    
    func dispatch(action: StateAction) {
        Self.reducer(state: &state.value, action: action)
    }

    class func reducer(state: inout State, action: StateAction) {

    }

    func process(viewAction: ViewAction) {

    }
}
