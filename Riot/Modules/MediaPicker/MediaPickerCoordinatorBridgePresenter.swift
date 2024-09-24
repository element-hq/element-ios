// File created from FlowTemplate
// $ createRootCoordinator.sh Test MediaPicker
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol MediaPickerCoordinatorBridgePresenterDelegate {
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?)
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectVideo videoAsset: AVAsset)
    func mediaPickerCoordinatorBridgePresenter(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter, didSelectAssets assets: [PHAsset])
    func mediaPickerCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: MediaPickerCoordinatorBridgePresenter)
}

/// MediaPickerCoordinatorBridgePresenter enables to start MediaPickerCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class MediaPickerCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let mediaUTIs: [MXKUTI]
    private let allowsMultipleSelection: Bool
    private var coordinator: MediaPickerCoordinator?
    
    // MARK: Public
    
    weak var delegate: MediaPickerCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, mediaUTIs: [MXKUTI], allowsMultipleSelection: Bool) {
        self.session = session
        self.mediaUTIs = mediaUTIs
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init()
    }
    
    // MARK: - Public
        
    func present(from viewController: UIViewController,
                 sourceView: UIView?,
                 sourceRect: CGRect,
                 animated: Bool) {
        let mediaPickerCoordinator = MediaPickerCoordinator(session: self.session, mediaUTIs: mediaUTIs, allowsMultipleSelection: self.allowsMultipleSelection)
        mediaPickerCoordinator.delegate = self
        
        let mediaPickerPresentable = mediaPickerCoordinator.toPresentable()
        
        if let sourceView = sourceView {

            mediaPickerPresentable.modalPresentationStyle = .popover

            if let popoverPresentationController = mediaPickerPresentable.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView

                let finalSourceRect: CGRect

                if sourceRect != CGRect.null {
                    finalSourceRect = sourceRect
                } else {
                    finalSourceRect = sourceView.bounds
                }

                popoverPresentationController.sourceRect = finalSourceRect
            }
        }
        
        viewController.present(mediaPickerPresentable, animated: animated, completion: nil)
        
        mediaPickerCoordinator.start()
        
        self.coordinator = mediaPickerCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
            
            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - MediaPickerCoordinatorDelegate
extension MediaPickerCoordinatorBridgePresenter: MediaPickerCoordinatorDelegate {
    
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        self.delegate?.mediaPickerCoordinatorBridgePresenter(self, didSelectImageData: imageData, withUTI: uti)
    }
    
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectVideo videoAsset: AVAsset) {
        self.delegate?.mediaPickerCoordinatorBridgePresenter(self, didSelectVideo: videoAsset)
    }
    
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectAssets assets: [PHAsset]) {
        self.delegate?.mediaPickerCoordinatorBridgePresenter(self, didSelectAssets: assets)
    }
    
    func mediaPickerCoordinatorDidCancel(_ coordinator: MediaPickerCoordinatorType) {
        self.delegate?.mediaPickerCoordinatorBridgePresenterDidCancel(self)
    }
}
