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
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
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
