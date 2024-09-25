/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit
import AVFoundation

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
        self.cameraAccessManager = CameraAccessManager()
        self.cameraAccessAlertPresenter = CameraAccessAlertPresenter()
        super.init()
    }
    
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
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        guard self.cameraAccessManager.isCameraAvailable else {
            self.cameraAccessAlertPresenter.presentCameraUnavailableAlert(from: presentingViewController, animated: animated)
            return
        }
        
        self.cameraAccessManager.askAndRequestCameraAccessIfNeeded { (granted) in
            if granted {
                self.presentCameraController(animated: animated)
            } else {
                self.cameraAccessAlertPresenter.presentPermissionDeniedAlert(from: presentingViewController, animated: animated)
            }
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
        imagePickerController.videoQuality = .typeHigh
        imagePickerController.allowsEditing = false
        
        return imagePickerController
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CameraPresenter: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.delegate?.cameraPresenter(self, didSelectVideoAt: videoURL)
        } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            self.delegate?.cameraPresenter(self, didSelectImage: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.delegate?.cameraPresenterDidCancel(self)
    }
}

// MARK: - UINavigationControllerDelegate
extension CameraPresenter: UINavigationControllerDelegate {
}
