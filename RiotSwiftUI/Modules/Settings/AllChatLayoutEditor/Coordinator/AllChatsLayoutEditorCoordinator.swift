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

struct AllChatsLayoutEditorCoordinatorParameters {
    let settings: AllChatsLayoutSettings
    let session: MXSession
}

final class AllChatsLayoutEditorCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AllChatsLayoutEditorCoordinatorParameters
    private let hostingViewController: UIViewController
    private var viewModel: AllChatsLayoutEditorViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    private let adaptivePresentationDelegate = AdaptivePresentationDelegate()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((_ result: AllChatsLayoutEditorCoordinatorResult) -> Void)? {
        didSet {
            adaptivePresentationDelegate.completion = completion
        }
    }
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: AllChatsLayoutEditorCoordinatorParameters) {
        self.parameters = parameters
        let service = AllChatsLayoutEditorService(session: parameters.session, settings: parameters.settings)
        let viewModel = AllChatsLayoutEditorViewModel.makeAllChatsLayoutEditorViewModel(service: service)
        let view = AllChatsLayoutEditor(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        self.viewModel = viewModel
        hostingViewController = VectorHostingController(rootView: view)
        hostingViewController.presentationController?.delegate = adaptivePresentationDelegate

        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingViewController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AllChatLayoutEditorCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AllChatLayoutEditorCoordinator] AllChatLayoutEditorViewModel did complete with result: \(result).")
            
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .done(let newSettings):
                self.completion?(.done(newSettings))
            case .addPinnedSpace:
                self.showSpaceSelector()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.hostingViewController
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
    
    private func showSpaceSelector() {
        let coordinator = SpaceSelectorBottomSheetCoordinator(parameters: SpaceSelectorBottomSheetCoordinatorParameters(session: parameters.session))
        coordinator.start()
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel: break
            case .allSelected: break
            case .spaceSelected(let item):
                self.viewModel.pinSpace(with: item)
            }
            
            coordinator.toPresentable().dismiss(animated: true)
            self.remove(childCoordinator: coordinator)
        }
        self.add(childCoordinator: coordinator)
        self.hostingViewController.present(coordinator.toPresentable(), animated: true)
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate

    private class AdaptivePresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
        var completion: ((_ result: AllChatsLayoutEditorCoordinatorResult) -> Void)?
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            self.completion?(.cancel)
        }
    }
}
