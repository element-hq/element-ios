// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationMatrixItemChooser SpaceCreationMatrixItemChooser
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


@available(iOS 14, *)
typealias SpaceCreationMatrixItemChooserViewModelType = StateStoreViewModel<SpaceCreationMatrixItemListStateActionListViewState,
                                                                            SpaceCreationMatrixItemListStateAction,
                                                                            SpaceCreationMatrixItemListStateActionListViewAction>
@available(iOS 14, *)
class SpaceCreationMatrixItemChooserViewModel: SpaceCreationMatrixItemChooserViewModelType, SpaceCreationMatrixItemChooserViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private var spaceCreationMatrixItemChooserService: SpaceCreationMatrixItemChooserServiceProtocol
    private var creationParams: SpaceCreationParameters

    // MARK: Public

    var callback: ((SpaceCreationMatrixItemListStateActionListViewModelAction) -> Void)?

    // MARK: - Setup

    static func makeSpaceCreationMatrixItemChooserViewModel(spaceCreationMatrixItemChooserService: SpaceCreationMatrixItemChooserServiceProtocol, creationParams: SpaceCreationParameters) -> SpaceCreationMatrixItemChooserViewModelProtocol {
        return SpaceCreationMatrixItemChooserViewModel(spaceCreationMatrixItemChooserService: spaceCreationMatrixItemChooserService, creationParams: creationParams)
    }

    private init(spaceCreationMatrixItemChooserService: SpaceCreationMatrixItemChooserServiceProtocol, creationParams: SpaceCreationParameters) {
        self.spaceCreationMatrixItemChooserService = spaceCreationMatrixItemChooserService
        self.creationParams = creationParams
        super.init(initialViewState: Self.defaultState(spaceCreationMatrixItemChooserService: spaceCreationMatrixItemChooserService, creationParams: creationParams))
        startObservingItems()
    }

    private static func defaultState(spaceCreationMatrixItemChooserService: SpaceCreationMatrixItemChooserServiceProtocol, creationParams: SpaceCreationParameters) -> SpaceCreationMatrixItemListStateActionListViewState {
        let navTitle = creationParams.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle
        let title = spaceCreationMatrixItemChooserService.type == .people ? VectorL10n.spacesCreationInviteByUsernameTitle : VectorL10n.spacesCreationAddRoomsTitle
        let message = spaceCreationMatrixItemChooserService.type == .people ? VectorL10n.spacesCreationInviteByUsernameMessage : VectorL10n.spacesCreationAddRoomsMessage
        let emptyListMessage = VectorL10n.spacesNoResultFoundTitle

        return SpaceCreationMatrixItemListStateActionListViewState(navTitle: navTitle, title: title, message: message, emptyListMessage: emptyListMessage, items: spaceCreationMatrixItemChooserService.itemsSubject.value, selectedItemIds: spaceCreationMatrixItemChooserService.selectedItemIdsSubject.value)
    }

    private func startObservingItems() {
        let itemsUpdatePublisher = spaceCreationMatrixItemChooserService.itemsSubject
            .map(SpaceCreationMatrixItemListStateAction.updateItems)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: itemsUpdatePublisher)
        
        let selectionPublisher = spaceCreationMatrixItemChooserService.selectedItemIdsSubject
            .map(SpaceCreationMatrixItemListStateAction.updateSelection)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: selectionPublisher)
    }

    // MARK: - Public

    override func process(viewAction: SpaceCreationMatrixItemListStateActionListViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .back:
            back()
        case .done:
            let selectedItemIds = Array(spaceCreationMatrixItemChooserService.selectedItemIdsSubject.value)
            switch spaceCreationMatrixItemChooserService.type {
            case .people:
                creationParams.userIdInvites = selectedItemIds
            default:
                creationParams.addedRoomIds = selectedItemIds
            }
            done()
        case .searchTextChanged(let searchText):
            self.spaceCreationMatrixItemChooserService.searchText = searchText
        case .itemTapped(let itemId):
            self.spaceCreationMatrixItemChooserService.reverseSelectionForItem(withId: itemId)
        }
    }

    override class func reducer(state: inout SpaceCreationMatrixItemListStateActionListViewState, action: SpaceCreationMatrixItemListStateAction) {
        switch action {
        case .updateItems(let items):
            state.items = items
        case .updateSelection(let selectedItemIds):
            state.selectedItemIds = selectedItemIds
        }
        UILog.debug("[SpaceCreationMatrixItemChooserViewModel] reducer with action \(action) produced state: \(state)")
    }

    private func done() {
        callback?(.done)
    }

    private func cancel() {
        callback?(.cancel)
    }
    
    private func back() {
        callback?(.back)
    }
}
