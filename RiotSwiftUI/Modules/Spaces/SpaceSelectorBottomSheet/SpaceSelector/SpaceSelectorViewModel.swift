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

typealias SpaceSelectorViewModelType = StateStoreViewModel<SpaceSelectorViewState, SpaceSelectorViewAction>

class SpaceSelectorViewModel: SpaceSelectorViewModelType, SpaceSelectorViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let service: SpaceSelectorServiceProtocol

    // MARK: Public

    var completion: ((SpaceSelectorViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeViewModel(service: SpaceSelectorServiceProtocol, showCancel: Bool) -> SpaceSelectorViewModelProtocol {
        SpaceSelectorViewModel(service: service, showCancel: showCancel)
    }

    private init(service: SpaceSelectorServiceProtocol, showCancel: Bool) {
        self.service = service
        super.init(initialViewState: Self.defaultState(service: service, showCancel: showCancel))
        setupObservers()
    }

    private static func defaultState(service: SpaceSelectorServiceProtocol, showCancel: Bool) -> SpaceSelectorViewState {
        let parentName = service.parentSpaceNameSubject.value
        return SpaceSelectorViewState(items: service.spaceListSubject.value,
                                      selectedSpaceId: service.selectedSpaceId,
                                      navigationTitle: parentName ?? VectorL10n.spaceSelectorTitle,
                                      showCancel: showCancel)
    }
    
    private func setupObservers() {
        service.spaceListSubject.sink { [weak self] spaceList in
            self?.state.items = spaceList
        }
        .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: SpaceSelectorViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .spaceSelected(let item):
            if item.id == SpaceSelectorConstants.homeSpaceId {
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
