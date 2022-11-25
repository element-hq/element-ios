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

@available(iOS 14.0, *)
struct MessageContextMenuCoordinatorParameters {
    let session: MXSession
    let event: MXEvent
    let cell: MXKRoomBubbleTableViewCell
    let roomDataSource: MXKRoomDataSource
    let canEndPoll: Bool
}

@available(iOS 14.0, *)
final class MessageContextMenuCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: MessageContextMenuCoordinatorParameters
    private let hostingController: UIViewController
    private var viewModel: MessageContextMenuViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((MessageContextMenuCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: MessageContextMenuCoordinatorParameters) {
        self.parameters = parameters
        let service = MessageContextMenuService(session: parameters.session,
                                                event: parameters.event,
                                                cell: parameters.cell,
                                                roomDataSource: parameters.roomDataSource,
                                                canEndPoll: parameters.canEndPoll)
        let viewModel = MessageContextMenuViewModel.makeMessageContextMenuViewModel(service: service)
        let view = MessageContextMenu(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        self.viewModel = viewModel
        hostingController = VectorHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[MessageContextMenuCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[MessageContextMenuCoordinator] MessageContextMenuViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .done(let actionType):
                self.completion?(.done(actionType))
            case .updateReaction(let reaction, let isSelected):
                self.completion?(.updateReaction(reaction, isSelected))
            case .moreReactions:
                self.completion?(.moreReactions)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.hostingController
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
