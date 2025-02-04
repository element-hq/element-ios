// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
