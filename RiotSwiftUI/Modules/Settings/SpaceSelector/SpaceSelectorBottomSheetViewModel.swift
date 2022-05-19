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
typealias SpaceSelectorBottomSheetViewModelType = StateStoreViewModel<SpaceSelectorBottomSheetViewState,
                                                                 Never,
                                                                 SpaceSelectorBottomSheetViewAction>
@available(iOS 14, *)
class SpaceSelectorBottomSheetViewModel: SpaceSelectorBottomSheetViewModelType, SpaceSelectorBottomSheetViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let spaceSelectorBottomSheetService: SpaceSelectorBottomSheetServiceProtocol

    // MARK: Public

    var completion: ((SpaceSelectorBottomSheetViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeSpaceSelectorBottomSheetViewModel(spaceSelectorBottomSheetService: SpaceSelectorBottomSheetServiceProtocol) -> SpaceSelectorBottomSheetViewModelProtocol {
        return SpaceSelectorBottomSheetViewModel(spaceSelectorBottomSheetService: spaceSelectorBottomSheetService)
    }

    private init(spaceSelectorBottomSheetService: SpaceSelectorBottomSheetServiceProtocol) {
        self.spaceSelectorBottomSheetService = spaceSelectorBottomSheetService
        super.init(initialViewState: Self.defaultState(spaceSelectorBottomSheetService: spaceSelectorBottomSheetService))
    }

    private static func defaultState(spaceSelectorBottomSheetService: SpaceSelectorBottomSheetServiceProtocol) -> SpaceSelectorBottomSheetViewState {
        return SpaceSelectorBottomSheetViewState(items: spaceSelectorBottomSheetService.spaceListSubject.value)
    }
    
    // MARK: - Public

    override func process(viewAction: SpaceSelectorBottomSheetViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .spaceSelected(let item):
            if item.id == SpaceSelectorListItemDataAllId {
                completion?(.allSelected)
            } else {
                completion?(.spaceSelected(item))
            }
        }
    }
}
