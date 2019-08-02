/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit
import AVFoundation

@objc protocol CameraPresenterDelegate: class {
    func cameraPresenter(_ presenter: CameraPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?)
    func cameraPresenter(_ presenter: CameraPresenter, didSelectVideoAt url: URL)
    func cameraPresenterDidCancel(_ cameraPresenter: CameraPresenter)
}

/// CameraPresenter enables to present native camera
@objc final class CameraPresenter: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let jpegCompressionQuality: CGFloat = 1.0
    }
    
    // MARK: - Properties
    
    // MARK: - Private
    
    private weak var presentingViewController: UIViewController?
    private weak var cameraViewController: UIViewController?
    private var mediaUTIs: [MXKUTI] = []
    
    // MARK: - Public
    
    @objc weak var delegate: CameraPresenterDelegate?
    
    // MARK: - Public
    
    @objc func presentCamera(from presentingViewController: UIViewController, with mediaUTIs: [MXKUTI], animated: Bool) {
        self.presentingViewController = presentingViewController
        self.mediaUTIs = mediaUTIs
        self.checkCameraPermissionAndPresentCamera(animated: animated)
    }
    
    @objc func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let cameraViewController = self.cameraViewController else {
            return
        }
        cameraViewController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func checkCameraPermissionAndPresentCamera(animated: Bool) {
        
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            self.presentCameraController(animated: animated)
        case .notDetermined:
            self.requestCameraAccess(completion: { (granted) in
                if granted {
                    self.presentCameraController(animated: animated)
                } else {
                    self.presentPermissionDeniedAlert()
                }
            })
        case .denied, .restricted:
            self.presentPermissionDeniedAlert()
        @unknown default:
            break
        }
    }
    
    private func presentCameraController(animated: Bool) {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        guard let cameraViewController = self.buildCameraViewController() else {
            return
        }
        
        presentingViewController.present(cameraViewController, animated: true, completion: nil)
        self.cameraViewController = cameraViewController
    }
    
    private func buildCameraViewController() -> UIViewController? {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            return nil
        }
        
        let mediaTypes = self.mediaUTIs.map { (uti) -> String in
            return uti.rawValue
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.camera
        imagePickerController.mediaTypes = mediaTypes
        imagePickerController.allowsEditing = false
        
        return imagePickerController
    }
    
    private func requestCameraAccess(completion: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func presentPermissionDeniedAlert() {
        guard let presentingViewController = self.presentingViewController, let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        let appDisplayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
        
        let alert = UIAlertController(title: VectorL10n.camera, message: VectorL10n.cameraAccessNotGranted(appDisplayName), preferredStyle: .alert)
        
        let cancelActionTitle = Bundle.mxk_localizedString(forKey: "ok")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: { _ in
        })
        
        let settingsActionTitle = Bundle.mxk_localizedString(forKey: "settings")
        let settingsAction = UIAlertAction(title: settingsActionTitle, style: .default, handler: { _ in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: { (succeed) in
                if !succeed {
                    print("[CameraPresenter] Fails to open settings")
                }
            })
        })
        
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        
        presentingViewController.present(alert, animated: true, completion: nil)
    }
    
    private func presentCameraUnavailableAlert() {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        let alert = UIAlertController(title: VectorL10n.camera, message: VectorL10n.cameraUnavailable, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: VectorL10n.accept, style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        presentingViewController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CameraPresenter: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.delegate?.cameraPresenter(self, didSelectVideoAt: videoURL)
        } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage, let imageData = image.jpegData(compressionQuality: Constants.jpegCompressionQuality) {
            self.delegate?.cameraPresenter(self, didSelectImageData: imageData, withUTI: MXKUTI.jpeg)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.delegate?.cameraPresenterDidCancel(self)
    }
}

// MARK: - UINavigationControllerDelegate
extension CameraPresenter: UINavigationControllerDelegate {
}
