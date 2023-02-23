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

typealias MatrixItemChooserViewModelType = StateStoreViewModel<MatrixItemChooserViewState, MatrixItemChooserViewAction>

class MatrixItemChooserViewModel: MatrixItemChooserViewModelType, MatrixItemChooserViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private var matrixItemChooserService: MatrixItemChooserServiceProtocol

    private var isLoading = false {
        didSet {
            state.loading = isLoading
            if isLoading {
                state.error = nil
            }
        }
    }
    
    // MARK: Public

    var completion: ((MatrixItemChooserViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeMatrixItemChooserViewModel(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?, selectionHeader: MatrixItemChooserSelectionHeader?) -> MatrixItemChooserViewModelProtocol {
        MatrixItemChooserViewModel(matrixItemChooserService: matrixItemChooserService, title: title, detail: detail, selectionHeader: selectionHeader)
    }

    private init(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?, selectionHeader: MatrixItemChooserSelectionHeader?) {
        self.matrixItemChooserService = matrixItemChooserService
        super.init(initialViewState: Self.defaultState(service: matrixItemChooserService, title: title, detail: detail, selectionHeader: selectionHeader))
        startObservingItems()
    }

    private static func defaultState(service: MatrixItemChooserServiceProtocol, title: String?, detail: String?, selectionHeader: MatrixItemChooserSelectionHeader?) -> MatrixItemChooserViewState {
        let title = title
        let message = detail
        let emptyListMessage = VectorL10n.spacesNoResultFoundTitle

        return MatrixItemChooserViewState(title: title, message: message, emptyListMessage: emptyListMessage, sections: service.sectionsSubject.value, itemCount: service.itemCount, selectedItemIds: service.selectedItemIdsSubject.value, loadingText: service.loadingText, loading: false, selectionHeader: selectionHeader)
    }

    private func startObservingItems() {
        matrixItemChooserService.sectionsSubject.sink { [weak self] sections in
            self?.state.sections = sections
            self?.state.itemCount = self?.matrixItemChooserService.itemCount ?? 0
        }
        .store(in: &cancellables)
        matrixItemChooserService.selectedItemIdsSubject.sink { [weak self] selectedItemIds in
            self?.state.selectedItemIds = selectedItemIds
        }
        .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: MatrixItemChooserViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .back:
            back()
        case .done:
            isLoading = true
            matrixItemChooserService.processSelection { [weak self] result in
                guard let self = self else { return }
                
                self.isLoading = false

                switch result {
                case .success:
                    let selectedItemsId = Array(self.matrixItemChooserService.selectedItemIdsSubject.value)
                    self.done(selectedItemsId: selectedItemsId)
                case .failure(let error):
                    self.matrixItemChooserService.refresh()
                    self.state.error = error.localizedDescription
                }
            }
        case .searchTextChanged(let searchText):
            matrixItemChooserService.searchText = searchText
        case .itemTapped(let itemId):
            matrixItemChooserService.reverseSelectionForItem(withId: itemId)
        case .selectAll:
            matrixItemChooserService.selectAllItems()
        case .selectNone:
            matrixItemChooserService.deselectAllItems()
        }
    }
    
    private func done(selectedItemsId: [String]) {
        completion?(.done(selectedItemsId))
    }

    private func cancel() {
        completion?(.cancel)
    }
    
    private func back() {
        completion?(.back)
    }
}
