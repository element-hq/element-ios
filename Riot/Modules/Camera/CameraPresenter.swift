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

import AVFoundation
import Foundation
import UIKit

@objc protocol CameraPresenterDelegate: AnyObject {
    func cameraPresenter(_ presenter: CameraPresenter, didSelectImage image: UIImage)
    func cameraPresenter(_ presenter: CameraPresenter, didSelectVideoAt url: URL)
    func cameraPresenterDidCancel(_ cameraPresenter: CameraPresenter)
}

/// CameraPresenter enables to present native camera
@objc final class CameraPresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let cameraAccessManager: CameraAccessManager
    private let cameraAccessAlertPresenter: CameraAccessAlertPresenter
    
    private weak var presentingViewController: UIViewController?
    private weak var cameraViewController: UIViewController?
    private var mediaUTIs: [MXKUTI] = []
    
    // MARK: Public
    
    @objc weak var delegate: CameraPresenterDelegate?
    
    // MARK: - Setup
    
    override init() {
        cameraAccessManager = CameraAccessManager()
        cameraAccessAlertPresenter = CameraAccessAlertPresenter()
        super.init()
    }
    
    // MARK: - Public
    
    @objc func presentCamera(from presentingViewController: UIViewController, with mediaUTIs: [MXKUTI], animated: Bool) {
        self.presentingViewController = presentingViewController
        self.mediaUTIs = mediaUTIs
        checkCameraPermissionAndPresentCamera(animated: animated)
    }
    
    @objc func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let cameraViewController = cameraViewController else {
            return
        }
        cameraViewController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func checkCameraPermissionAndPresentCamera(animated: Bool) {
        guard let presentingViewController = presentingViewController else {
            return
        }
        
        guard cameraAccessManager.isCameraAvailable else {
            cameraAccessAlertPresenter.presentCameraUnavailableAlert(from: presentingViewController, animated: animated)
            return
        }
        
        cameraAccessManager.askAndRequestCameraAccessIfNeeded { granted in
            if granted {
                self.presentCameraController(animated: animated)
            } else {
                self.cameraAccessAlertPresenter.presentPermissionDeniedAlert(from: presentingViewController, animated: animated)
            }
        }
    }
    
    private func presentCameraController(animated: Bool) {
        guard let presentingViewController = presentingViewController else {
            return
        }
        
        guard let cameraViewController = buildCameraViewController() else {
            return
        }
        
        presentingViewController.present(cameraViewController, animated: true, completion: nil)
        self.cameraViewController = cameraViewController
    }
    
    private func buildCameraViewController() -> UIViewController? {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            return nil
        }
        
        let mediaTypes = mediaUTIs.map { uti -> String in
            uti.rawValue
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.camera
        imagePickerController.mediaTypes = mediaTypes
        imagePickerController.videoQuality = .typeHigh
        imagePickerController.allowsEditing = false
        
        return imagePickerController
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CameraPresenter: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            delegate?.cameraPresenter(self, didSelectVideoAt: videoURL)
        } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            delegate?.cameraPresenter(self, didSelectImage: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.cameraPresenterDidCancel(self)
    }
}

// MARK: - UINavigationControllerDelegate

extension CameraPresenter: UINavigationControllerDelegate { }
