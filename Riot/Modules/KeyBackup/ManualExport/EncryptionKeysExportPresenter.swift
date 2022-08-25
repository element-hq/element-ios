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
        activityViewPresenter = ActivityIndicatorPresenter()
        keyExportFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(Constants.keyExportFileName)
        super.init()
    }
    
    deinit {
        self.deleteKeyExportFile()
    }
    
    // MARK: - Public

    func present(from viewController: UIViewController, sourceView: UIView?) {
        presentingViewController = viewController
        self.sourceView = sourceView
        
        let keysExportView = MXKEncryptionKeysExportView(matrixSession: session)

        // Make sure the file is empty
        deleteKeyExportFile()

        keysExportView.show(in: viewController,
                            toExportKeysToFile: keyExportFileURL,
                            onLoading: { [weak self] loading in

                                guard let self = self else {
                                    return
                                }
                            
                                if loading {
                                    self.activityViewPresenter.presentActivityIndicator(on: viewController.view, animated: true)
                                } else {
                                    self.activityViewPresenter.removeCurrentActivityIndicator(animated: true)
                                }
                            }, onComplete: { [weak self] success in
                                guard let self = self else {
                                    return
                                }

                                guard success else {
                                    self.encryptionKeysExportView = nil
                                    return
                                }

                                self.presentInteractionDocumentController()
                            })
        
        encryptionKeysExportView = keysExportView
    }
    
    // MARK: - Private

    private func presentInteractionDocumentController() {
        let sourceRect: CGRect
        
        guard let presentingView = presentingViewController?.view else {
            encryptionKeysExportView = nil
            return
        }
        
        if let sourceView = sourceView {
            sourceRect = sourceView.convert(sourceView.bounds, to: presentingView)
        } else {
            sourceRect = presentingView.bounds
        }
        
        let documentInteractionController = UIDocumentInteractionController(url: keyExportFileURL)
        documentInteractionController.delegate = self

        if documentInteractionController.presentOptionsMenu(from: sourceRect, in: presentingView, animated: true) {
            self.documentInteractionController = documentInteractionController
        } else {
            encryptionKeysExportView = nil
            deleteKeyExportFile()
        }
    }

    @objc private func deleteKeyExportFile() {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: keyExportFileURL.path) {
            try? fileManager.removeItem(atPath: keyExportFileURL.path)
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension EncryptionKeysExportPresenter: UIDocumentInteractionControllerDelegate {
    // Note: This method is not called in all cases (see http://stackoverflow.com/a/21867096).
    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        deleteKeyExportFile()
        documentInteractionController = nil
    }
    
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        encryptionKeysExportView = nil
        documentInteractionController = nil
    }
}
