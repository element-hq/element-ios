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

import CommonKit
import SwiftUI

struct SpaceSelectorCoordinatorParameters {
    let session: MXSession
    let parentSpaceId: String?
    let selectedSpaceId: String?
    let showHomeSpace: Bool
    let showCancel: Bool
    
    init(session: MXSession,
         parentSpaceId: String? = nil,
         selectedSpaceId: String? = nil,
         showHomeSpace: Bool = false,
         showCancel: Bool) {
        self.session = session
        self.parentSpaceId = parentSpaceId
        self.selectedSpaceId = selectedSpaceId
        self.showHomeSpace = showHomeSpace
        self.showCancel = showCancel
    }
}

final class SpaceSelectorCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceSelectorCoordinatorParameters
    private let hostingViewController: UIViewController
    private var viewModel: SpaceSelectorViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((SpaceSelectorCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceSelectorCoordinatorParameters) {
        self.parameters = parameters
        let service = SpaceSelectorService(session: parameters.session, parentSpaceId: parameters.parentSpaceId, showHomeSpace: parameters.showHomeSpace, selectedSpaceId: parameters.selectedSpaceId)
        let viewModel = SpaceSelectorViewModel.makeViewModel(service: service, showCancel: parameters.showCancel)
        let view = SpaceSelector(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        self.viewModel = viewModel
        let hostingViewController = VectorHostingController(rootView: view)
        hostingViewController.hidesBackTitleWhenPushed = true
        self.hostingViewController = hostingViewController
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: self.hostingViewController)
    }
    
    // MARK: - Public
    
    func start() {
        if let room = parameters.session.room(withRoomId: parameters.parentSpaceId) {
            Analytics.shared.trackViewRoom(room)
        }

        MXLog.debug("[SpaceSelectorCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[SpaceSheetCoordinator] SpaceSelectorViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .homeSelected:
                self.completion?(.homeSelected)
            case .spaceSelected(let item):
                self.completion?(.spaceSelected(item))
            case .spaceDisclosure(let item):
                self.completion?(.spaceDisclosure(item))
            case .createSpace:
                self.completion?(.createSpace(self.parameters.parentSpaceId))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        hostingViewController
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
