/*
 Copyright 2019 The Matrix.org Foundation C.I.C
 
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
import MobileCoreServices

@objc public protocol MXKDocumentPickerPresenterDelegate {
    func documentPickerPresenter(_ presenter: MXKDocumentPickerPresenter, didPickDocumentsAt url: URL)
    func documentPickerPresenterWasCancelled(_ presenter: MXKDocumentPickerPresenter)
}

/// MXKDocumentPickerPresenter presents a controller that provides access to documents or destinations outside the app’s sandbox.
/// Internally presents a UIDocumentPickerViewController in UIDocumentPickerMode.import.
/// Note: You must turn on the iCloud Documents capabilities in Xcode
/// (see https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/DocumentPickerProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014451)
@objcMembers
public class MXKDocumentPickerPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    
    // MARK: Public
    
    public weak var delegate: MXKDocumentPickerPresenterDelegate?
    
    public var isPresenting: Bool {
        return self.presentingViewController?.parent != nil
    }
    
    // MARK: - Public
    
    /// Presents a document picker view controller modally.
    ///
    /// - Parameters:
    ///   - allowedUTIs: Allowed pickable file UTIs.
    ///   - viewController: The view controller on which to present the document picker.
    ///   - animated: Indicate true to animate.
    ///   - completion: Animation completion.
    public func presentDocumentPicker(with allowedUTIs: [MXKUTI], from viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let documentTypes = allowedUTIs.map { return $0.rawValue }
        let documentPicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: animated, completion: completion)
        self.presentingViewController = viewController
    }
}

// MARK - UIDocumentPickerDelegate
extension MXKDocumentPickerPresenter: UIDocumentPickerDelegate {
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        self.delegate?.documentPickerPresenter(self, didPickDocumentsAt: url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.delegate?.documentPickerPresenterWasCancelled(self)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.delegate?.documentPickerPresenter(self, didPickDocumentsAt: url)
    }
}
