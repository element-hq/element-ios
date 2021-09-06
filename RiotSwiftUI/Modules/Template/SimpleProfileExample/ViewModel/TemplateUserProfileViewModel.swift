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
class TemplateUserProfileViewModel: ObservableObject {
    
    private let userService: TemplateUserServiceType
    private var cancellables =  Set<AnyCancellable>()
    
    @Published private(set) var viewState: TemplateUserProfileViewState
    
    private static func defaultState(userService: TemplateUserServiceType) -> TemplateUserProfileViewState {
        return TemplateUserProfileViewState(avatar: userService.avatarData, displayName: userService.displayName)
    }
    
    init(userService: TemplateUserServiceType, initialState: TemplateUserProfileViewState? = nil) {
        self.userService = userService
        self.viewState = initialState ?? Self.defaultState(userService: userService)
        
        userService.presencePublisher
            .map(TemplateProfileStateAction.updatePresence)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: self.dispatch(action:))
            .store(in: &cancellables)
    }
    
    /**
     Send state actions to mutate the state.
     */
    private func dispatch(action: TemplateProfileStateAction) {
        var newState = self.viewState
        reducer(state: &newState, action: action)
        self.viewState = newState
    }
    
    /**
     A redux style reducer, all modifications to state happen here. Recieves a state and a state action and produces a new state.
     */
    private func reducer(state: inout TemplateUserProfileViewState, action: TemplateProfileStateAction) {
        switch action {
        case .updatePresence(let presence):
            state.presence = presence
        }
    }
}
