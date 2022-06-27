// 
// Copyright 2022 New Vector Ltd
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

import UIKit
import PhotosUI
import CommonKit

protocol MediaPickerPresenterDelegate: AnyObject {
    func mediaPickerPresenter(_ presenter: MediaPickerPresenter, didPickImage image: UIImage)
    func mediaPickerPresenterDidCancel(_ presenter: MediaPickerPresenter)
}

/// A picker for photos and videos from the user's photo library on iOS 14+ using the
/// new `PHPickerViewController` that doesn't require permission to be granted.
final class MediaPickerPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var pickerViewController: UIViewController?
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol?
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public
    
    weak var delegate: MediaPickerPresenterDelegate?
    
    // MARK: - Public
    
    // TODO: Support videos and multi-selection
    func presentPicker(from presentingViewController: UIViewController, with filter: PHPickerFilter?, animated: Bool) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = filter
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        
        self.pickerViewController = pickerViewController
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: pickerViewController)
        
        presentingViewController.present(pickerViewController, animated: true, completion: nil)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let pickerViewController = pickerViewController else { return }
        pickerViewController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func showLoadingIndicator() {
        loadingIndicator = indicatorPresenter?.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator = nil
    }
}

// MARK: - PHPickerViewControllerDelegate
extension MediaPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // TODO: Handle videos and multi-selection
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            self.delegate?.mediaPickerPresenterDidCancel(self)
            return
        }
        
        showLoadingIndicator()
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self else { return }
            
            guard let image = image as? UIImage else {
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                    self.delegate?.mediaPickerPresenterDidCancel(self)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.delegate?.mediaPickerPresenter(self, didPickImage: image)
            }
        }
    }
}
