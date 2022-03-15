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
import MatrixSDK

struct OnboardingAvatarCoordinatorParameters {
    let userSession: UserSession
}

@available(iOS 14.0, *)
final class OnboardingAvatarCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingAvatarCoordinatorParameters
    private let onboardingAvatarHostingController: VectorHostingController
    private var onboardingAvatarViewModel: OnboardingAvatarViewModelProtocol
    
    private lazy var cameraPresenter: CameraPresenter = {
        let presenter = CameraPresenter()
        presenter.delegate = self
        return presenter
    }()
    
    private lazy var photoPickerPresenter: PhotoPickerPresenter = {
        let presenter = PhotoPickerPresenter()
        presenter.delegate = self
        return presenter
    }()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSession) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingAvatarCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = OnboardingAvatarViewModel(userId: parameters.userSession.userId,
                                                  displayName: parameters.userSession.account.userDisplayName,
                                                  avatarColorCount: DefaultThemeSwiftUI().colors.namesAndAvatars.count)
        let view = OnboardingAvatarScreen(viewModel: viewModel.context)
        onboardingAvatarViewModel = viewModel
        onboardingAvatarHostingController = VectorHostingController(rootView: view)
        onboardingAvatarHostingController.vc_removeBackTitle()
        onboardingAvatarHostingController.enableNavigationBarScrollEdgesAppearance = true
    }
    
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[OnboardingAvatarCoordinator] did start.")
        onboardingAvatarViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[OnboardingAvatarCoordinator] OnboardingAvatarViewModel did complete with result: \(result).")
            switch result {
            case .pickImage:
                self.pickImage()
            case .takePhoto:
                self.takePhoto()
            case .save(let avatar):
                self.setAvatar(avatar)
            case .skip:
                self.completion?(self.parameters.userSession)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingAvatarHostingController
    }
    
    // MARK: - Private
    
    private func pickImage() {
        let controller = toPresentable()
        photoPickerPresenter.presentPicker(from: controller, with: .images, animated: true)
    }
    
    private func takePhoto() {
        let controller = toPresentable()
        cameraPresenter.presentCamera(from: controller, with: [.image], animated: true)
    }
    
    private lazy var mediaUploader: MXMediaLoader = MXMediaManager.prepareUploader(withMatrixSession: parameters.userSession.matrixSession,
                                                                                   initialRange: 0,
                                                                                   andRange: 1.0)
    
    #warning("Temporary")
    func unknownError() -> Error {
        MXError(errorCode: "M.UNKNOWN", error: "Something went wrong!").createNSError()
    }
    
    func setAvatar(_ image: UIImage?) {
        guard let image = image else {
            MXLog.error("[OnboardingAvatarCoordinator] setAvatar called with a nil image.")
            return
        }
        
        onboardingAvatarViewModel.startLoading()
        
        guard let avatarData = MXKTools.forceImageOrientationUp(image)?.jpegData(compressionQuality: 0.5) else {
            MXLog.error("[OnboardingAvatarCoordinator] Failed to create jpeg data.")
            self.onboardingAvatarViewModel.stopLoading(error: self.unknownError())
            return
        }
        
        mediaUploader.uploadData(avatarData, filename: nil, mimeType: "image/jpeg") { [weak self] urlString in
            guard let self = self else { return }
            
            guard let urlString = urlString else {
                self.onboardingAvatarViewModel.stopLoading(error: self.unknownError())
                return
            }
            
            self.parameters.userSession.account.setUserAvatarUrl(urlString) { [weak self] in
                guard let self = self else { return }
                self.completion?(self.parameters.userSession)
            } failure: { [weak self] error in
                guard let self = self else { return }
                self.onboardingAvatarViewModel.stopLoading(error: error ?? self.unknownError())
            }
        } failure: { [weak self] error in
            guard let self = self else { return }
            self.onboardingAvatarViewModel.stopLoading(error: error ?? self.unknownError())
        }
    }
}

// MARK: - PhotoPickerPresenterDelegate

@available(iOS 14.0, *)
extension OnboardingAvatarCoordinator: PhotoPickerPresenterDelegate {
    func photoPickerPresenter(_ presenter: PhotoPickerPresenter, didPickImage image: UIImage) {
        onboardingAvatarViewModel.updateAvatarImage(with: image)
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func photoPickerPresenterDidCancel(_ presenter: PhotoPickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CameraPresenterDelegate

@available(iOS 14.0, *)
extension OnboardingAvatarCoordinator: CameraPresenterDelegate {
    func cameraPresenter(_ presenter: CameraPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        onboardingAvatarViewModel.updateAvatarImage(with: UIImage(data: imageData))
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func cameraPresenter(_ presenter: CameraPresenter, didSelectVideoAt url: URL) {
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func cameraPresenterDidCancel(_ presenter: CameraPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}
