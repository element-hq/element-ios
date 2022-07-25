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
typealias SpaceSelectorViewModelType = StateStoreViewModel<SpaceSelectorViewState,
                                                                 Never,
                                                                 SpaceSelectorViewAction>
@available(iOS 14, *)
class SpaceSelectorViewModel: SpaceSelectorViewModelType, SpaceSelectorViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let service: SpaceSelectorServiceProtocol

    // MARK: Public

    var completion: ((SpaceSelectorViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeViewModel(service: SpaceSelectorServiceProtocol) -> SpaceSelectorViewModelProtocol {
        return SpaceSelectorViewModel(service: service)
    }

    private init(service: SpaceSelectorServiceProtocol) {
        self.service = service
        super.init(initialViewState: Self.defaultState(service: service))
    }

    private static func defaultState(service: SpaceSelectorServiceProtocol) -> SpaceSelectorViewState {
        return SpaceSelectorViewState(items: service.spaceListSubject.value,
                                      selectedSpaceId: service.selectedSpaceId,
                                      parentName: service.parentSpaceNameSubject.value)
    }
    
    // MARK: - Public

    override func process(viewAction: SpaceSelectorViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .spaceSelected(let item):
            if item.id == SpaceSelectorListItemDataHomeSpaceId {
                completion?(.homeSelected)
            } else {
                completion?(.spaceSelected(item))
            }
        case .spaceDisclosure(let item):
            completion?(.spaceDisclosure(item))
        case .createSpace:
            completion?(.createSpace)
        }
    }
}
