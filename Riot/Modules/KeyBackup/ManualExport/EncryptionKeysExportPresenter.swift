/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class EncryptionKeysExportPresenter: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let keyExportFileName = "element-keys.txt"
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let activityViewPresenter: ActivityIndicatorPresenterType
    private let keyExportFileURL: URL    
    
    private weak var presentingViewController: UIViewController?
    private weak var sourceView: UIView?
    private var encryptionKeysExportView: MXKEncryptionKeysExportView?
    private var documentInteractionController: UIDocumentInteractionController?
    
    // MARK: Public
    
    // MARK: - Setup

    init(session: MXSession) {
        self.session = session
        self.activityViewPresenter = ActivityIndicatorPresenter()
        self.keyExportFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(Constants.keyExportFileName)
        super.init()
    }
    
    deinit {
        self.deleteKeyExportFile()
    }
    
    // MARK: - Public

    func present(from viewController: UIViewController, sourceView: UIView?) {
        self.presentingViewController = viewController
        self.sourceView = sourceView
        
        let keysExportView: MXKEncryptionKeysExportView = MXKEncryptionKeysExportView(matrixSession: self.session)

        // Make sure the file is empty
        self.deleteKeyExportFile()

        keysExportView.show(in: viewController,
                         toExportKeysToFile: self.keyExportFileURL,
                         onLoading: { [weak self] (loading) in

                            guard let self = self else {
                                return
                            }
                            
                            if loading {
                                self.activityViewPresenter.presentActivityIndicator(on: viewController.view, animated: true)
                            } else {
                                self.activityViewPresenter.removeCurrentActivityIndicator(animated: true)
                            }
        }, onComplete: { [weak self] (success) in
            guard let self = self else {
                return
            }

            guard success else {
                self.encryptionKeysExportView = nil
                return
            }

            self.presentInteractionDocumentController()
        })
        
        self.encryptionKeysExportView = keysExportView
    }
    
    // MARK: - Private

    private func presentInteractionDocumentController() {
        
        let sourceRect: CGRect
        
        guard let presentingView = self.presentingViewController?.view else {
            self.encryptionKeysExportView = nil
            return
        }
        
        if let sourceView = self.sourceView {
            sourceRect = sourceView.convert(sourceView.bounds, to: presentingView)
        } else {
            sourceRect = presentingView.bounds
        }
        
        let documentInteractionController = UIDocumentInteractionController(url: self.keyExportFileURL)
        documentInteractionController.delegate = self

        if documentInteractionController.presentOptionsMenu(from: sourceRect, in: presentingView, animated: true) {
            self.documentInteractionController = documentInteractionController
        } else {
            self.encryptionKeysExportView = nil
            self.deleteKeyExportFile()
        }
    }

    @objc private func deleteKeyExportFile() {
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: self.keyExportFileURL.path) {
            try? fileManager.removeItem(atPath: self.keyExportFileURL.path)
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate
extension EncryptionKeysExportPresenter: UIDocumentInteractionControllerDelegate {

    // Note: This method is not called in all cases (see http://stackoverflow.com/a/21867096).
    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        self.deleteKeyExportFile()
        self.documentInteractionController = nil
    }
    
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        self.encryptionKeysExportView = nil
        self.documentInteractionController = nil
    }
}
