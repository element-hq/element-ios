/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
