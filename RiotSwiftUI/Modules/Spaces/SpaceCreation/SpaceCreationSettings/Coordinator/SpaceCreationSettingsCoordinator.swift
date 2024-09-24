// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import SwiftUI
import UIKit

final class SpaceCreationSettingsCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationSettingsCoordinatorParameters
    private let spaceCreationSettingsHostingController: UIViewController
    private var spaceCreationSettingsViewModel: SpaceCreationSettingsViewModelProtocol
    
    private lazy var singleImagePickerPresenter: SingleImagePickerPresenter = {
        let presenter = SingleImagePickerPresenter(session: parameters.session)
        presenter.delegate = self
        return presenter
    }()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationSettingsCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationSettingsCoordinatorParameters) {
        self.parameters = parameters
        let service = SpaceCreationSettingsService(roomName: parameters.creationParameters.name ?? "", userDefinedAddress: parameters.creationParameters.userDefinedAddress, session: parameters.session)
        let viewModel = SpaceCreationSettingsViewModel(spaceCreationSettingsService: service, creationParameters: parameters.creationParameters)
        let view = SpaceCreationSettings(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
        spaceCreationSettingsViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isNavigationBarHidden = true
        spaceCreationSettingsHostingController = hostingController
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceCreationSettingsCoordinator] did start.")
        spaceCreationSettingsViewModel.callback = { [weak self] result in
            MXLog.debug("[SpaceCreationSettingsCoordinator] SpaceCreationSettingsViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .done:
                self.callback?(.didSetupParameters)
            case .cancel:
                self.callback?(.cancel)
            case .back:
                self.callback?(.back)
            case .pickImage(let sourceRect):
                self.pickImage(from: sourceRect)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        spaceCreationSettingsHostingController
    }
    
    // MARK: - Private
    
    private func pickImage(from sourceRect: CGRect) {
        let controller = toPresentable()
        let adjustedRect = controller.view.convert(sourceRect, from: nil)
        singleImagePickerPresenter.present(from: controller, sourceView: controller.view, sourceRect: adjustedRect, animated: true)
    }
}

// MARK: - SingleImagePickerPresenterDelegate

extension SpaceCreationSettingsCoordinator: SingleImagePickerPresenterDelegate {
    func singleImagePickerPresenter(_ presenter: SingleImagePickerPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        spaceCreationSettingsViewModel.updateAvatarImage(with: UIImage(data: imageData))
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func singleImagePickerPresenterDidCancel(_ presenter: SingleImagePickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}
