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

@objc protocol SingleImagePickerPresenterDelegate: AnyObject {
    func singleImagePickerPresenter(_ presenter: SingleImagePickerPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?)
    func singleImagePickerPresenterDidCancel(_ presenter: SingleImagePickerPresenter)
}

/// SingleImagePickerPresenter enables to present an image picker with single selection
@objcMembers
final class SingleImagePickerPresenter: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let jpegCompressionQuality: CGFloat = 1.0
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    
    private weak var presentingViewController: UIViewController?
    private var cameraPresenter: CameraPresenter?
    private var mediaPickerPresenter: MediaPickerCoordinatorBridgePresenter?
    
    // MARK: Public
    
    weak var delegate: SingleImagePickerPresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func present(from presentingViewController: UIViewController,
                 sourceView: UIView?,
                 sourceRect: CGRect,
                 animated: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        let cameraAction = UIAlertAction(title: VectorL10n.imagePickerActionCamera, style: .default, handler: { _ in
            self.presentCamera(animated: animated)
        })
        
        let photoLibraryAction = UIAlertAction(title: VectorL10n.imagePickerActionLibrary, style: .default, handler: { _ in
            self.presentPhotoLibray(sourceView: sourceView, sourceRect: sourceRect, animated: animated)
        })
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel)
        
        alert.addAction(cameraAction)
        alert.addAction(photoLibraryAction)
        alert.addAction(cancelAction)
        
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
        }
        
        presentingViewController.present(alert, animated: animated, completion: nil)
        self.presentingViewController = presentingViewController
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if let cameraPresenter = self.cameraPresenter {
            cameraPresenter.dismiss(animated: animated, completion: completion)
        } else if let mediaPickerPresenter = self.mediaPickerPresenter {
            mediaPickerPresenter.dismiss(animated: animated, completion: completion)
        }
    }
    
    // MARK: - Private
    
    private func presentCamera(animated: Bool) {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        let cameraPresenter = CameraPresenter()
        cameraPresenter.delegate = self
        cameraPresenter.presentCamera(from: presentingViewController, with: [.image], animated: animated)
        self.cameraPresenter = cameraPresenter
    }
    
    private func presentPhotoLibray(sourceView: UIView?, sourceRect: CGRect, animated: Bool) {
        guard let presentingViewController = self.presentingViewController else {
            return
        }
        
        let mediaPickerPresenter = MediaPickerCoordinatorBridgePresenter(session: self.session, mediaUTIs: [.image], allowsMultipleSelection: false)
        mediaPickerPresenter.delegate = self
        
        mediaPickerPresenter.present(from: presentingViewController, sourceView: sourceView, sourceRect: sourceRect, animated: animated)
        self.mediaPickerPresenter = mediaPickerPresenter
    }
    
}

// MARK: - CameraPresenterDelegate
extension SingleImagePickerPresenter: CameraPresenterDelegate {
    
    func cameraPresenter(_ cameraPresenter: CameraPresenter, didSelectImage image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: Constants.jpegCompressionQuality) {
            self.delegate?.singleImagePickerPresenter(self, didSelectImageData: imageData, withUTI: MXKUTI.jpeg)
        }
    }
    
    func cameraPresenterDidCancel(_ cameraPresenter: CameraPresenter) {
        self.delegate?.singleImagePickerPresenterDidCancel(self)
    }
    
    func cameraPresenter(_ cameraPresenter: CameraPresenter, didSelectVideoAt url: URL) {
        self.delegate?.singleImagePickerPresenterDidCancel(self)
    }
}
// MARK: - MediaPickerCoordinatorBridgePresenterDelegate
extension SingleImagePickerPresenter: MediaPickerCoordinatorBridgePresenterDelegate {
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        self.delegate?.singleImagePickerPresenter(self, didSelectImageData: imageData, withUTI: uti)
    }
    
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectVideo videoAsset: AVAsset) {
        self.delegate?.singleImagePickerPresenterDidCancel(self)
    }
    
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectAssets assets: [PHAsset]) {
        self.delegate?.singleImagePickerPresenterDidCancel(self)
    }
    
    func mediaPickerCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter) {
        self.delegate?.singleImagePickerPresenterDidCancel(self)
    }
}
