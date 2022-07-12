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
typealias AllChatsLayoutEditorViewModelType = StateStoreViewModel<AllChatsLayoutEditorViewState,
                                                                 Never,
                                                                 AllChatsLayoutEditorViewAction>
@available(iOS 14, *)
class AllChatsLayoutEditorViewModel: AllChatsLayoutEditorViewModelType, AllChatsLayoutEditorViewModelProtocol {
    
    // MARK: - Properties

    // MARK: Private

    private let service: AllChatsLayoutEditorServiceProtocol

    // MARK: Public

    var completion: ((AllChatsLayoutEditorViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeAllChatsLayoutEditorViewModel(service: AllChatsLayoutEditorServiceProtocol) -> AllChatsLayoutEditorViewModelProtocol {
        return AllChatsLayoutEditorViewModel(service: service)
    }

    private init(service: AllChatsLayoutEditorServiceProtocol) {
        self.service = service
        super.init(initialViewState: Self.defaultState(service: service))
    }

    private static func defaultState(service: AllChatsLayoutEditorServiceProtocol) -> AllChatsLayoutEditorViewState {
        return AllChatsLayoutEditorViewState(sections: service.sections,
                                            filters: service.filters,
                                            sortingOptions: service.sortingOptions)
    }
    
    // MARK: - Public

    override func process(viewAction: AllChatsLayoutEditorViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .done:
            service.trackDoneAction(sections: state.sections, filters: state.filters, sortingOptions: state.sortingOptions)
            completion?(.done(service.outputSettings(sections: state.sections, filters: state.filters, sortingOptions: state.sortingOptions)))
        case .tappedSectionItem(let sectionItem):
            revertSelection(of: sectionItem)
        case .tappedFilterItem(let filter):
            revertSelection(of: filter)
        case .tappedSortingOption(let option):
            updateSelection(of: option)
        }
    }
    
    // MARK: - Private
    
    private func revertSelection(of sectionItem: AllChatsLayoutEditorSection) {
        guard let index = state.sections.firstIndex(of: sectionItem) else {
            return
        }
        
        state.sections[index].selected = !state.sections[index].selected
    }
    
    private func revertSelection(of filter: AllChatsLayoutEditorFilter) {
        guard let index = state.filters.firstIndex(of: filter) else {
            return
        }
        
        state.filters[index].selected = !state.filters[index].selected
    }
    
    private func updateSelection(of filter: AllChatsLayoutEditorSortingOption) {
        for i in 0..<state.sortingOptions.count {
            state.sortingOptions[i].selected = state.sortingOptions[i].id == filter.id
        }
    }
}
