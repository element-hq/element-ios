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
typealias MatrixItemChooserViewModelType = StateStoreViewModel<MatrixItemChooserViewState,
                                                                 MatrixItemChooserStateAction,
                                                                 MatrixItemChooserViewAction>
@available(iOS 14, *)
class MatrixItemChooserViewModel: MatrixItemChooserViewModelType, MatrixItemChooserViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private var matrixItemChooserService: MatrixItemChooserServiceProtocol

    // MARK: Public

    var completion: ((MatrixItemChooserViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeMatrixItemChooserViewModel(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?) -> MatrixItemChooserViewModelProtocol {
        return MatrixItemChooserViewModel(matrixItemChooserService: matrixItemChooserService, title: title, detail: detail)
    }

    private init(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?) {
        self.matrixItemChooserService = matrixItemChooserService
        super.init(initialViewState: Self.defaultState(matrixItemChooserService: matrixItemChooserService, title: title, detail: detail))
        startObservingItems()
    }

    private static func defaultState(matrixItemChooserService: MatrixItemChooserServiceProtocol, title: String?, detail: String?) -> MatrixItemChooserViewState {
        let title = title
        let message = detail
        let emptyListMessage = VectorL10n.spacesNoResultFoundTitle

        return MatrixItemChooserViewState(title: title, message: message, emptyListMessage: emptyListMessage, sections: matrixItemChooserService.sectionsSubject.value, selectedItemIds: matrixItemChooserService.selectedItemIdsSubject.value, loadingText: matrixItemChooserService.loadingText, loading: false)
    }

    private func startObservingItems() {
        let sectionsUpdatePublisher = matrixItemChooserService.sectionsSubject
            .map(MatrixItemChooserStateAction.updateSections)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: sectionsUpdatePublisher)
        
        let selectionPublisher = matrixItemChooserService.selectedItemIdsSubject
            .map(MatrixItemChooserStateAction.updateSelection)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: selectionPublisher)
    }

    // MARK: - Public

    override func process(viewAction: MatrixItemChooserViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .back:
            back()
        case .done:
            dispatch(action: .loadingState(true))
            matrixItemChooserService.processSelection { [weak self] result in
                guard let self = self else { return }
                
                self.dispatch(action: .loadingState(false))

                switch result {
                case .success:
                    let selectedItemsId = Array(self.matrixItemChooserService.selectedItemIdsSubject.value)
                    self.done(selectedItemsId: selectedItemsId)
                case .failure(let error):
                    self.matrixItemChooserService.refresh()
                    self.dispatch(action: .updateError(error))
                }
            }
        case .searchTextChanged(let searchText):
            self.matrixItemChooserService.searchText = searchText
        case .itemTapped(let itemId):
            self.matrixItemChooserService.reverseSelectionForItem(withId: itemId)
        }
    }

    override class func reducer(state: inout MatrixItemChooserViewState, action: MatrixItemChooserStateAction) {
        switch action {
        case .updateSections(let sections):
            state.sections = sections
        case .updateSelection(let selectedItemIds):
            state.selectedItemIds = selectedItemIds
        case .loadingState(let loading):
            state.loading = loading
            state.error = nil
        case .updateError(let error):
            state.error = error?.localizedDescription
        }
        UILog.debug("[MatrixItemChooserViewModel] reducer with action \(action) produced state: \(state)")
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
