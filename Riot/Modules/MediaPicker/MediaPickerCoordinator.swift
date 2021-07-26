// File created from FlowTemplate
// $ createRootCoordinator.sh Test MediaPicker
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

import UIKit

final class MediaPickerCoordinator: NSObject, MediaPickerCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let mediaUTIs: [MXKUTI]
    private let allowsMultipleSelection: Bool
    
    private let navigationRouter: NavigationRouterType
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: MediaPickerCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, mediaUTIs: [MXKUTI], allowsMultipleSelection: Bool) {
        self.session = session
        self.mediaUTIs = mediaUTIs
        self.allowsMultipleSelection = allowsMultipleSelection
        
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        
        super.init()
    }
    
    // MARK: - Public methods
    
    func start() {
        let mediaTypes = self.mediaUTIs.map { (uti) -> String in
            return uti.rawValue
        }
        
        let mediaPickerViewController: MediaPickerViewController = MediaPickerViewController.instantiate()
        mediaPickerViewController.mediaTypes = mediaTypes
        mediaPickerViewController.allowsMultipleSelection = self.allowsMultipleSelection
        self.navigationRouter.setRootModule(mediaPickerViewController)
        mediaPickerViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
}

// MARK: - MediaPickerViewControllerDelegate
extension MediaPickerCoordinator: MediaPickerViewControllerDelegate {
    
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectImage imageData: Data!, withMimeType mimetype: String!, isPhotoLibraryAsset: Bool) {
        
        let uti: MXKUTI?
        if let mimetype = mimetype {
            uti = MXKUTI(mimeType: mimetype)
        } else {
            uti = nil
        }
        
        self.delegate?.mediaPickerCoordinator(self, didSelectImageData: imageData, withUTI: uti)
    }
    
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelectVideo videoAsset: AVAsset!) {
        self.delegate?.mediaPickerCoordinator(self, didSelectVideo: videoAsset)
    }
    
    func mediaPickerController(_ mediaPickerController: MediaPickerViewController!, didSelect assets: [PHAsset]!) {
        self.delegate?.mediaPickerCoordinator(self, didSelectAssets: assets)
    }
    
    func mediaPickerControllerDidCancel(_ mediaPickerController: MediaPickerViewController!) {
        self.delegate?.mediaPickerCoordinatorDidCancel(self)
    }
}
