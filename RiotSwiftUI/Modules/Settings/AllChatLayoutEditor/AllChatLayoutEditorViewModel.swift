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
typealias AllChatLayoutEditorViewModelType = StateStoreViewModel<AllChatLayoutEditorViewState,
                                                                 Never,
                                                                 AllChatLayoutEditorViewAction>
@available(iOS 14, *)
class AllChatLayoutEditorViewModel: AllChatLayoutEditorViewModelType, AllChatLayoutEditorViewModelProtocol {
    
    // MARK: - Properties

    // MARK: Private

    private let service: AllChatLayoutEditorServiceProtocol

    // MARK: Public

    var completion: ((AllChatLayoutEditorViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeAllChatLayoutEditorViewModel(service: AllChatLayoutEditorServiceProtocol) -> AllChatLayoutEditorViewModelProtocol {
        return AllChatLayoutEditorViewModel(service: service)
    }

    private init(service: AllChatLayoutEditorServiceProtocol) {
        self.service = service
        super.init(initialViewState: Self.defaultState(service: service))
    }

    private static func defaultState(service: AllChatLayoutEditorServiceProtocol) -> AllChatLayoutEditorViewState {
        return AllChatLayoutEditorViewState(sections: service.sections,
                                            filters: service.filters,
                                            sortingOptions: service.sortingOptions,
                                            pinnedSpaces: service.pinnedSpaces)
    }
    
    // MARK: - Public

    func pinSpace(with item: SpaceSelectorListItemData) {
        guard state.pinnedSpaces.firstIndex(of: item) == nil else {
            return
        }
        
        state.pinnedSpaces.append(item)
    }

    override func process(viewAction: AllChatLayoutEditorViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .done:
            service.trackDoneAction(sections: state.sections, filters: state.filters, sortingOptions: state.sortingOptions, pinnedSpaces: state.pinnedSpaces)
            completion?(.done(service.outputSettings(sections: state.sections, filters: state.filters, sortingOptions: state.sortingOptions, pinnedSpaces: state.pinnedSpaces)))
        case .tappedSectionItem(let sectionItem):
            revertSelection(of: sectionItem)
        case .tappedFilterItem(let filter):
            revertSelection(of: filter)
        case .tappedSortingOption(let option):
            updateSelection(of: option)
        case .addPinnedSpace:
            completion?(.addPinnedSpace)
        case .removePinnedSpace(let item):
            if let index = state.pinnedSpaces.firstIndex(of: item) {
                state.pinnedSpaces.remove(at: index)
            }
        }
    }
    
    // MARK: - Private
    
    private func revertSelection(of sectionItem: AllChatLayoutEditorSection) {
        guard let index = state.sections.firstIndex(of: sectionItem) else {
            return
        }
        
        state.sections[index].selected = !state.sections[index].selected
    }
    
    private func revertSelection(of filter: AllChatLayoutEditorFilter) {
        guard let index = state.filters.firstIndex(of: filter) else {
            return
        }
        
        state.filters[index].selected = !state.filters[index].selected
    }
    
    private func updateSelection(of filter: AllChatLayoutEditorSortingOption) {
        for i in 0..<state.sortingOptions.count {
            state.sortingOptions[i].selected = state.sortingOptions[i].id == filter.id
        }
    }
}
