// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
/*
 Copyright 2020 New Vector Ltd
 
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

import MatrixSDK
import UIKit

final class KeyVerificationVerifyByScanningViewController: UIViewController {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var closeButton: UIButton!
    
    @IBOutlet private var titleView: UIView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var codeImageView: UIImageView!
    
    @IBOutlet private var scanCodeButton: UIButton!
    @IBOutlet private var cannotScanButton: UIButton!
    
    @IBOutlet private var qrCodeContainerView: UIView!
    
    @IBOutlet private var scanButtonContainerView: UIView!
    
    // MARK: Private

    private var viewModel: KeyVerificationVerifyByScanningViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var cameraAccessAlertPresenter: CameraAccessAlertPresenter!
    private var cameraAccessManager: CameraAccessManager!
    
    private weak var qrCodeReaderViewController: QRCodeReaderViewController?
    
    private var alertPresentingViewController: UIViewController {
        qrCodeReaderViewController ?? self
    }

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationVerifyByScanningViewModelType) -> KeyVerificationVerifyByScanningViewController {
        let viewController = StoryboardScene.KeyVerificationVerifyByScanningViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupViews()
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        cameraAccessAlertPresenter = CameraAccessAlertPresenter()
        cameraAccessManager = CameraAccessManager()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        
        if let themableCloseButton = closeButton as? Themable {
            themableCloseButton.update(theme: theme)
        }

        theme.applyStyle(onButton: scanCodeButton)
        theme.applyStyle(onButton: cannotScanButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        titleView.isHidden = navigationController != nil
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        title = VectorL10n.keyVerificationVerifyQrCodeTitle
        titleLabel.text = VectorL10n.keyVerificationVerifyQrCodeTitle
        informationLabel.text = VectorL10n.keyVerificationVerifyQrCodeInformation
        
        // Hide until we have the type of the verification request
        scanCodeButton.isHidden = true

        cannotScanButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeCannotScanAction, for: .normal)
    }

    private func render(viewState: KeyVerificationVerifyByScanningViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(viewData: let viewData):
            renderLoaded(viewData: viewData)
        case .error(let error):
            render(error: error)
        case .scannedCodeValidated(let isValid):
            renderScannedCode(valid: isValid)
        case .cancelled(let reason, let verificationKind):
            renderCancelled(reason: reason, verificationKind: verificationKind)
        case .cancelledByMe(let reason):
            renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationVerifyByScanningViewData) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let hideQRCodeImage: Bool
        
        if let qrCodePayloadData = viewData.qrCodeData {
            hideQRCodeImage = false
            codeImageView.image = qrCodeImage(from: qrCodePayloadData)
        } else {
            hideQRCodeImage = true
        }
        
        title = viewData.verificationKind.verificationTitle
        titleLabel.text = viewData.verificationKind.verificationTitle
        qrCodeContainerView.isHidden = hideQRCodeImage
        scanButtonContainerView.isHidden = !viewData.showScanAction
        
        if viewData.qrCodeData == nil, viewData.showScanAction == false {
            // Update the copy if QR code scanning is not possible at all
            informationLabel.text = VectorL10n.keyVerificationVerifyQrCodeEmojiInformation
            cannotScanButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeStartEmojiAction, for: .normal)
        } else {
            let informationText: String
            
            switch viewData.verificationKind {
            case .user:
                informationText = VectorL10n.keyVerificationVerifyQrCodeInformation
                scanCodeButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeScanCodeAction, for: .normal)
            default:
                informationText = VectorL10n.keyVerificationVerifyQrCodeInformationOtherDevice
                scanCodeButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeScanCodeOtherDeviceAction, for: .normal)
            }
            
            scanCodeButton.isHidden = false
            informationLabel.text = informationText
        }
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func qrCodeImage(from data: Data) -> UIImage? {
        let codeGenerator = QRCodeGenerator()
        do {
            return try codeGenerator.generateCode(from: data, with: codeImageView.frame.size)
        } catch {
            MXLog.error("[KeyVerificationVerifyByScanningViewController] qrCodeImage: cannot generate QR code", context: error)
            return nil
        }
    }
    
    private func presentQRCodeReader(animated: Bool) {
        let qrCodeViewController = QRCodeReaderViewController.instantiate()
        qrCodeViewController.delegate = self
        present(qrCodeViewController, animated: animated, completion: nil)
        qrCodeReaderViewController = qrCodeViewController
    }
    
    private func renderScannedCode(valid: Bool) {
        if valid {
            stopQRCodeScanningIfPresented()
            presentCodeValidated(animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: true, completion: {
                    self.viewModel.process(viewAction: .acknowledgeMyUserScannedOtherCode)
                })
            }
        }
    }
    
    private func renderCancelled(reason: MXTransactionCancelCode,
                                 verificationKind: KeyVerificationKind) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
    
        stopQRCodeScanningIfPresented()
        
        // if we're verifying with someone else, let the user know they cancelled.
        // if we're verifying our own device, assume the user probably knows since it was them who
        // cancelled on their other device
        if verificationKind == .user {
            errorPresenter.presentError(from: alertPresentingViewController, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: false)
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            dismissQRCodeScanningIfPresented(animated: false)
            viewModel.process(viewAction: .cancel)
        }
    }
    
    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            activityPresenter.removeCurrentActivityIndicator(animated: true)
            
            errorPresenter.presentError(from: alertPresentingViewController, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: false)
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    private func presentCodeValidated(animated: Bool, completion: @escaping (() -> Void)) {
        let alert = UIAlertController(title: VectorL10n.keyVerificationVerifyQrCodeScanOtherCodeSuccessTitle,
                                      message: VectorL10n.keyVerificationVerifyQrCodeScanOtherCodeSuccessMessage,
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: VectorL10n.ok, style: .default, handler: { _ in
            completion()
        })
        alert.addAction(okAction)
        
        if let qrCodeReaderViewController = qrCodeReaderViewController {
            qrCodeReaderViewController.present(alert, animated: animated, completion: nil)
        }
    }
    
    private func checkCameraAccessAndPresentQRCodeReader(animated: Bool) {
        guard cameraAccessManager.isCameraAvailable else {
            cameraAccessAlertPresenter.presentCameraUnavailableAlert(from: self, animated: animated)
            return
        }
        
        cameraAccessManager.askAndRequestCameraAccessIfNeeded { granted in
            if granted {
                self.presentQRCodeReader(animated: animated)
            } else {
                self.cameraAccessAlertPresenter.presentPermissionDeniedAlert(from: self, animated: animated)
            }
        }
    }
    
    private func stopQRCodeScanningIfPresented() {
        guard let qrCodeReaderViewController = qrCodeReaderViewController else {
            return
        }
        qrCodeReaderViewController.view.isUserInteractionEnabled = false
        qrCodeReaderViewController.stopScanning()
    }
    
    private func dismissQRCodeScanningIfPresented(animated: Bool, completion: (() -> Void)? = nil) {
        guard qrCodeReaderViewController?.presentingViewController != nil else {
            return
        }
        dismiss(animated: animated, completion: completion)
    }

    // MARK: - Actions

    @IBAction private func scanButtonAction(_ sender: Any) {
        checkCameraAccessAndPresentQRCodeReader(animated: true)
    }
    
    @IBAction private func cannotScanAction(_ sender: Any) {
        viewModel.process(viewAction: .cannotScan)
    }
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .cancel)
    }
    
    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - KeyVerificationVerifyByScanningViewModelViewDelegate

extension KeyVerificationVerifyByScanningViewController: KeyVerificationVerifyByScanningViewModelViewDelegate {
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyByScanningViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - QRCodeReaderViewControllerDelegate

extension KeyVerificationVerifyByScanningViewController: QRCodeReaderViewControllerDelegate {
    func qrCodeReaderViewController(_ viewController: QRCodeReaderViewController, didFound payloadData: Data) {
        viewModel.process(viewAction: .scannedCode(payloadData: payloadData))
    }
    
    func qrCodeReaderViewControllerDidCancel(_ viewController: QRCodeReaderViewController) {
        dismissQRCodeScanningIfPresented(animated: true)
    }
}
