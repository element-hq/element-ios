// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

import Combine
import SwiftUI
    
typealias SpaceCreationMenuViewModelType = StateStoreViewModel<SpaceCreationMenuViewState, SpaceCreationMenuViewAction>

class SpaceCreationMenuViewModel: SpaceCreationMenuViewModelType, SpaceCreationMenuViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private

    let creationParams: SpaceCreationParameters
    
    // MARK: Public
    
    var callback: ((SpaceCreationMenuViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(navTitle: String?, creationParams: SpaceCreationParameters, title: String, detail: String, options: [SpaceCreationMenuRoomOption]) {
        self.creationParams = creationParams
        
        super.init(initialViewState: SpaceCreationMenuViewModel.defaultState(navTitle: navTitle, creationParams: creationParams, title: title, detail: detail, options: options))
    }
    
    private static func defaultState(navTitle: String?, creationParams: SpaceCreationParameters, title: String, detail: String, options: [SpaceCreationMenuRoomOption]) -> SpaceCreationMenuViewState {
        var navigationTitle = ""
        if let navTitle = navTitle {
            navigationTitle = navTitle
        } else {
            navigationTitle = creationParams.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle
        }
        
        return SpaceCreationMenuViewState(navTitle: navigationTitle, title: title, detail: detail, options: options)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceCreationMenuViewAction) {
        switch viewAction {
        case .didSelectOption(let optionId):
            switch optionId {
            case .publicSpace:
                creationParams.isPublic = true
            case .privateSpace:
                creationParams.isPublic = false
            case .ownedPrivateSpace:
                creationParams.isShared = false
            case .sharedPrivateSpace:
                creationParams.isShared = true
            }

            didSelectOption(withId: optionId)
        case .cancel:
            done()
        case .back:
            back()
        }
    }
    
    // MARK: - Private
    
    private func done() {
        callback?(.cancel)
    }
    
    private func back() {
        callback?(.back)
    }
    
    private func didSelectOption(withId optionId: SpaceCreationMenuRoomOptionId) {
        callback?(.didSelectOption(optionId))
    }
}
