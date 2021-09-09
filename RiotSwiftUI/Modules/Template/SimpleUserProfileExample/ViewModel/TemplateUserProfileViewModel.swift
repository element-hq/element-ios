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
import Combine
    
@available(iOS 14.0, *)
class TemplateUserProfileViewModel: ObservableObject, TemplateUserProfileViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    private let userService: TemplateUserProfileServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    @Published private(set) var viewState: TemplateUserProfileViewState
    
    var completion: ((TemplateUserProfileViewModelResult) -> Void)?
    
    // MARK: - Setup
    init(userService: TemplateUserProfileServiceProtocol, initialState: TemplateUserProfileViewState? = nil) {
        self.userService = userService
        self.viewState = initialState ?? Self.defaultState(userService: userService)
        
        userService.presencePublisher
            .map(TemplateUserProfileStateAction.updatePresence)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] action in
                self?.dispatch(action:action)
            })
            .store(in: &cancellables)
    }
    
    private static func defaultState(userService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewState {
        return TemplateUserProfileViewState(avatar: userService.avatarData, displayName: userService.displayName, presence: .offline)
    }
    
    // MARK: - Public
    func proccess(viewAction: TemplateUserProfileViewAction) {
        switch viewAction {
        case .cancel:
            self.cancel()
        case .done:
            self.done()
        }
    }
    
    // MARK: - Private
    /**
     Send state actions to mutate the state.
     */
    private func dispatch(action: TemplateUserProfileStateAction) {
        Self.reducer(state: &self.viewState, action: action)
    }
    
    /**
     A redux style reducer, all modifications to state happen here. Recieves a state and a state action and produces a new state.
     */
    private static func reducer(state: inout TemplateUserProfileViewState, action: TemplateUserProfileStateAction) {
        switch action {
        case .updatePresence(let presence):
            state.presence = presence
        }
//        TODO: Uncomment when we have an abstract logger for RiotSwiftUI
//        MXLog.debug("[TemplateUserProfileViewModel] reducer with action \(action) produced state: \(state)")
    }
    
    private func done() {
        completion?(.done)
    }
    
    private func cancel() {
        completion?(.cancel)
    }
}
