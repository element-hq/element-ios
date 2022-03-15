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

@available(iOS 14.0, *)
protocol PhotoPickerPresenterDelegate: AnyObject {
    func photoPickerPresenter(_ presenter: PhotoPickerPresenter, didPickImage image: UIImage)
    func photoPickerPresenterDidCancel(_ presenter: PhotoPickerPresenter)
}

/// A picker for photos and videos from the user's photo library on iOS 14+ using the
/// new `PHPickerViewController` that doesn't require permission to be granted.
@available(iOS 14.0, *)
final class PhotoPickerPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var pickerViewController: UIViewController?
    private var filter: PHPickerFilter?
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol?
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public
    
    weak var delegate: PhotoPickerPresenterDelegate?
    
    // MARK: - Public
    
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
    
    func showLoadingIndicator() {
        loadingIndicator = indicatorPresenter?.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    func hideLoadingIndicator() {
        loadingIndicator?.cancel()
        loadingIndicator = nil
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14, *)
extension PhotoPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // TODO: Handle videos and multi-selection
        guard
            let provider = results.first?.itemProvider,
            provider.canLoadObject(ofClass: UIImage.self)
        else {
            self.delegate?.photoPickerPresenterDidCancel(self)
            return
        }
        
        showLoadingIndicator()
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self else { return }
            
            guard let image = image as? UIImage else {
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                    self.delegate?.photoPickerPresenterDidCancel(self)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.delegate?.photoPickerPresenter(self, didPickImage: image)
            }
        }
    }
}
