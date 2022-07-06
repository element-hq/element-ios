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
import CommonKit

struct SpaceSelectorBottomSheetCoordinatorParameters {
    let session: MXSession
    let spaceIds: [String]?
    let isAllEnabled: Bool
    
    init(session: MXSession,
         spaceIds: [String]? = nil,
         isAllEnabled: Bool = false) {
        self.session = session
        self.spaceIds = spaceIds
        self.isAllEnabled = isAllEnabled
    }
}

final class SpaceSelectorBottomSheetCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceSelectorBottomSheetCoordinatorParameters
    private let spaceSelectorBottomSheetHostingController: UIViewController
    private var spaceSelectorBottomSheetViewModel: SpaceSelectorBottomSheetViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((SpaceSelectorBottomSheetCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: SpaceSelectorBottomSheetCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = SpaceSelectorBottomSheetViewModel.makeSpaceSelectorBottomSheetViewModel(spaceSelectorBottomSheetService: SpaceSelectorBottomSheetService(session: parameters.session, spaceIds: parameters.spaceIds, isAllEnabled: parameters.isAllEnabled))
        let view = SpaceSelectorBottomSheet(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        spaceSelectorBottomSheetViewModel = viewModel
        let hostingViewController = VectorHostingController(rootView: view)
        hostingViewController.bottomSheetPreferences = VectorHostingBottomSheetPreferences()
        spaceSelectorBottomSheetHostingController = hostingViewController
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: spaceSelectorBottomSheetHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceSelectorBottomSheetCoordinator] did start.")
        spaceSelectorBottomSheetViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[SpaceSelectorBottomSheetCoordinator] SpaceSelectorBottomSheetViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .allSelected:
                self.completion?(.allSelected)
            case .spaceSelected(let item):
                self.completion?(.spaceSelected(item))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceSelectorBottomSheetHostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
