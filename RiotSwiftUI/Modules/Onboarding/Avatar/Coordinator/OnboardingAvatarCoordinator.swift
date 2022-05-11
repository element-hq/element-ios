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

struct OnboardingAvatarCoordinatorParameters {
    let userSession: UserSession
    /// An optional image that can be set to pre-fill the avatar.
    let avatar: UIImage?
}

enum OnboardingAvatarCoordinatorResult {
    /// The user has chosen an image (but it won't be uploaded until `.complete` is sent).
    /// This result is to cache the image in the flow coordinator so it can be restored if the user was to navigate backwards.
    case selectedAvatar(UIImage?)
    /// The screen is finished and the next one can be shown.
    case complete(UserSession)
}

final class OnboardingAvatarCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingAvatarCoordinatorParameters
    private let onboardingAvatarHostingController: VectorHostingController
    private var onboardingAvatarViewModel: OnboardingAvatarViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var waitingIndicator: UserIndicator?
    
    private lazy var cameraPresenter: CameraPresenter = {
        let presenter = CameraPresenter()
        presenter.delegate = self
        return presenter
    }()
    
    private lazy var mediaPickerPresenter: MediaPickerPresenter = {
        let presenter = MediaPickerPresenter()
        presenter.delegate = self
        return presenter
    }()
    
    private lazy var mediaUploader: MXMediaLoader = MXMediaManager.prepareUploader(withMatrixSession: parameters.userSession.matrixSession,
                                                                                   initialRange: 0,
                                                                                   andRange: 1.0)
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((OnboardingAvatarCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingAvatarCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = OnboardingAvatarViewModel(userId: parameters.userSession.userId,
                                                  displayName: parameters.userSession.account.userDisplayName,
                                                  avatarColorCount: DefaultThemeSwiftUI().colors.namesAndAvatars.count)
        viewModel.updateAvatarImage(with: parameters.avatar)
        
        let view = OnboardingAvatarScreen(viewModel: viewModel.context)
        onboardingAvatarViewModel = viewModel
        onboardingAvatarHostingController = VectorHostingController(rootView: view)
        onboardingAvatarHostingController.vc_removeBackTitle()
        onboardingAvatarHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingAvatarHostingController)
    }
    
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[OnboardingAvatarCoordinator] did start.")
        onboardingAvatarViewModel.callback = { [weak self] result in
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
                self.callback?(.complete(self.parameters.userSession))
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingAvatarHostingController
    }
    
    // MARK: - Private
    
    /// Show a blocking activity indicator whilst saving.
    private func startWaiting() {
        waitingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.saving, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopWaiting() {
        waitingIndicator = nil
    }
    
    /// Present an image picker for the device photo library.
    private func pickImage() {
        let controller = toPresentable()
        mediaPickerPresenter.presentPicker(from: controller, with: .images, animated: true)
    }
    
    /// Present a camera view to take a photo to use for the avatar.
    private func takePhoto() {
        let controller = toPresentable()
        cameraPresenter.presentCamera(from: controller, with: [.image], animated: true)
    }
    
    /// Set the supplied image as user's avatar, completing the screen's display if successful.
    func setAvatar(_ image: UIImage?) {
        guard let image = image else {
            MXLog.error("[OnboardingAvatarCoordinator] setAvatar called with a nil image.")
            return
        }
        
        startWaiting()
        
        guard let avatarData = MXKTools.forceImageOrientationUp(image)?.jpegData(compressionQuality: 0.5) else {
            MXLog.error("[OnboardingAvatarCoordinator] Failed to create jpeg data.")
            self.stopWaiting()
            self.onboardingAvatarViewModel.processError(nil)
            return
        }
        
        mediaUploader.uploadData(avatarData, filename: nil, mimeType: "image/jpeg") { [weak self] urlString in
            guard let self = self else { return }
            
            guard let urlString = urlString else {
                MXLog.error("[OnboardingAvatarCoordinator] Missing URL string for avatar.")
                self.stopWaiting()
                self.onboardingAvatarViewModel.processError(nil)
                return
            }
            
            self.parameters.userSession.account.setUserAvatarUrl(urlString) { [weak self] in
                guard let self = self else { return }
                self.stopWaiting()
                self.callback?(.complete(self.parameters.userSession))
            } failure: { [weak self] error in
                guard let self = self else { return }
                self.stopWaiting()
                self.onboardingAvatarViewModel.processError(error as NSError?)
            }
        } failure: { [weak self] error in
            guard let self = self else { return }
            self.stopWaiting()
            self.onboardingAvatarViewModel.processError(error as NSError?)
        }
    }
}

// MARK: - MediaPickerPresenterDelegate

extension OnboardingAvatarCoordinator: MediaPickerPresenterDelegate {
    /// **Note:** MediaPickerPresenter fails to load images on the simulator as of Xcode 13.3 (at least on an M1 Mac),
    /// so whilst this method may not appear to be called, everything works fine when run on a device.
    func mediaPickerPresenter(_ presenter: MediaPickerPresenter, didPickImage image: UIImage) {
        onboardingAvatarViewModel.updateAvatarImage(with: image)
        callback?(.selectedAvatar(image))
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerPresenterDidCancel(_ presenter: MediaPickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CameraPresenterDelegate

extension OnboardingAvatarCoordinator: CameraPresenterDelegate {
    func cameraPresenter(_ presenter: CameraPresenter, didSelectImage image: UIImage) {
        onboardingAvatarViewModel.updateAvatarImage(with: image)
        callback?(.selectedAvatar(image))
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func cameraPresenter(_ presenter: CameraPresenter, didSelectVideoAt url: URL) {
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func cameraPresenterDidCancel(_ presenter: CameraPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
}
