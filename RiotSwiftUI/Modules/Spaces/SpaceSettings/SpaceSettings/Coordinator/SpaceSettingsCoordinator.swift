//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SpaceSettingsCoordinatorParameters {
    let session: MXSession
    let spaceId: String
}

final class SpaceSettingsCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceSettingsCoordinatorParameters
    private let spaceSettingsHostingController: UIViewController
    private var spaceSettingsViewModel: SpaceSettingsViewModelProtocol
    
    private lazy var singleImagePickerPresenter: SingleImagePickerPresenter = {
        let presenter = SingleImagePickerPresenter(session: parameters.session)
        presenter.delegate = self
        return presenter
    }()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((SpaceSettingsCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceSettingsCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = SpaceSettingsViewModel.makeSpaceSettingsViewModel(service: SpaceSettingsService(session: parameters.session, spaceId: parameters.spaceId))
        let view = SpaceSettings(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))

        spaceSettingsViewModel = viewModel
        let controller = VectorHostingController(rootView: view)
        controller.enableNavigationBarScrollEdgeAppearance = true
        spaceSettingsHostingController = controller
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceSettingsCoordinator] did start.")
        spaceSettingsViewModel.completion = { [weak self] result in
            MXLog.debug("[SpaceSettingsCoordinator] SpaceSettingsViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .done:
                self.completion?(.done)
            case .optionScreen(let optionType):
                self.completion?(.optionScreen(optionType))
            case .pickImage(let sourceRect):
                self.pickImage(from: sourceRect)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        spaceSettingsHostingController
    }

    // MARK: - Private
    
    private func pickImage(from sourceRect: CGRect) {
        let controller = toPresentable()
        let adjustedRect = controller.view.convert(sourceRect, from: nil)
        singleImagePickerPresenter.present(from: controller, sourceView: controller.view, sourceRect: adjustedRect, animated: true)
    }
}

// MARK: - SingleImagePickerPresenterDelegate

extension SpaceSettingsCoordinator: SingleImagePickerPresenterDelegate {
    func singleImagePickerPresenter(_ presenter: SingleImagePickerPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        spaceSettingsViewModel.updateAvatarImage(with: UIImage(data: imageData))
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func singleImagePickerPresenterDidCancel(_ presenter: SingleImagePickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}
