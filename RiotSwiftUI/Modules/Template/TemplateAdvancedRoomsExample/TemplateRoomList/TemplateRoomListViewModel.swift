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

typealias TemplateRoomListViewModelType = StateStoreViewModel<TemplateRoomListViewState,
                                                              Never,
                                                              TemplateRoomListViewAction>

class TemplateRoomListViewModel: TemplateRoomListViewModelType, TemplateRoomListViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let templateRoomListService: TemplateRoomListServiceProtocol
    
    // MARK: Public
    
    var callback: ((TemplateRoomListViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(templateRoomListService: TemplateRoomListServiceProtocol) {
        self.templateRoomListService = templateRoomListService
        super.init(initialViewState: Self.defaultState(templateRoomListService: templateRoomListService))
        startObservingRooms()
    }
    
    private static func defaultState(templateRoomListService: TemplateRoomListServiceProtocol) -> TemplateRoomListViewState {
        return TemplateRoomListViewState(rooms: templateRoomListService.roomsSubject.value)
    }
    
    private func startObservingRooms() {
        templateRoomListService
            .roomsSubject
            .sink { [weak self] rooms in
                self?.state.rooms = rooms
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: TemplateRoomListViewAction) {
        switch viewAction {
        case .didSelectRoom(let roomId):
            didSelect(by: roomId)
        case .done:
            done()
        }
    }
    
    // MARK: - Private
    
    private func done() {
        callback?(.done)
    }
    
    private func didSelect(by roomId: String) {
        callback?(.didSelectRoom(roomId))
    }
}
