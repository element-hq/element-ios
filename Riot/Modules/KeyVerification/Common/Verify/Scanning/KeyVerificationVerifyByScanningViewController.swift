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

import UIKit
import MatrixSDK

final class KeyVerificationVerifyByScanningViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var closeButton: UIButton!
    
    @IBOutlet private weak var titleView: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var codeImageView: UIImageView!
    
    @IBOutlet private weak var scanCodeButton: UIButton!
    @IBOutlet private weak var cannotScanButton: UIButton!
    
    @IBOutlet private weak var qrCodeContainerView: UIView!
    
    @IBOutlet private weak var scanButtonContainerView: UIView!
    
    // MARK: Private

    private var viewModel: KeyVerificationVerifyByScanningViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var cameraAccessAlertPresenter: CameraAccessAlertPresenter!
    private var cameraAccessManager: CameraAccessManager!
    
    private weak var qrCodeReaderViewController: QRCodeReaderViewController?
    
    private var alertPresentingViewController: UIViewController {
        return self.qrCodeReaderViewController ?? self
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
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        self.cameraAccessAlertPresenter = CameraAccessAlertPresenter()
        self.cameraAccessManager = CameraAccessManager()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        
        if let themableCloseButton = self.closeButton as? Themable {
            themableCloseButton.update(theme: theme)
        }

        theme.applyStyle(onButton: self.scanCodeButton)
        theme.applyStyle(onButton: self.cannotScanButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.titleView.isHidden = self.navigationController != nil
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.title = VectorL10n.keyVerificationVerifyQrCodeTitle
        self.titleLabel.text = VectorL10n.keyVerificationVerifyQrCodeTitle
        self.informationLabel.text = VectorL10n.keyVerificationVerifyQrCodeInformation
        
        // Hide until we have the type of the verification request
        self.scanCodeButton.isHidden = true

        self.cannotScanButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeCannotScanAction, for: .normal)
    }

    private func render(viewState: KeyVerificationVerifyByScanningViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(viewData: let viewData):
            self.renderLoaded(viewData: viewData)
        case .error(let error):
            self.render(error: error)
        case .scannedCodeValidated(let isValid):
            self.renderScannedCode(valid: isValid)        
        case .cancelled(let reason, let verificationKind):
            self.renderCancelled(reason: reason, verificationKind: verificationKind)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(viewData: KeyVerificationVerifyByScanningViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        let hideQRCodeImage: Bool
        
        if let qrCodePayloadData = viewData.qrCodeData {
            hideQRCodeImage = false
            self.codeImageView.image = self.qrCodeImage(from: qrCodePayloadData)
        } else {
            hideQRCodeImage = true
        }
        
        self.title = viewData.verificationKind.verificationTitle
        self.titleLabel.text = viewData.verificationKind.verificationTitle
        self.qrCodeContainerView.isHidden = hideQRCodeImage
        self.scanButtonContainerView.isHidden = !viewData.showScanAction
        
        if viewData.qrCodeData == nil && viewData.showScanAction == false {
            // Update the copy if QR code scanning is not possible at all
            self.informationLabel.text = VectorL10n.keyVerificationVerifyQrCodeEmojiInformation
            self.cannotScanButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeStartEmojiAction, for: .normal)
        } else {
            let informationText: String
            
            switch viewData.verificationKind {
            case .user:
                informationText = VectorL10n.keyVerificationVerifyQrCodeInformation
                self.scanCodeButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeScanCodeAction, for: .normal)
            default:
                informationText = VectorL10n.keyVerificationVerifyQrCodeInformationOtherDevice
                self.scanCodeButton.setTitle(VectorL10n.keyVerificationVerifyQrCodeScanCodeOtherDeviceAction, for: .normal)
            }
            
            self.scanCodeButton.isHidden = false
            self.informationLabel.text = informationText
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
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
        self.present(qrCodeViewController, animated: animated, completion: nil)
        self.qrCodeReaderViewController = qrCodeViewController
    }
    
    private func renderScannedCode(valid: Bool) {
        if valid {
            self.stopQRCodeScanningIfPresented()
            self.presentCodeValidated(animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: true, completion: {
                    self.viewModel.process(viewAction: .acknowledgeMyUserScannedOtherCode)
                })
            }
        }
    }
    
    private func renderCancelled(reason: MXTransactionCancelCode,
                                 verificationKind: KeyVerificationKind) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    
        self.stopQRCodeScanningIfPresented()
        
        // if we're verifying with someone else, let the user know they cancelled.
        // if we're verifying our own device, assume the user probably knows since it was them who
        // cancelled on their other device
        if verificationKind == .user {
            self.errorPresenter.presentError(from: self.alertPresentingViewController, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: false)
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            self.dismissQRCodeScanningIfPresented(animated: false)
            self.viewModel.process(viewAction: .cancel)
        }
    }
    
    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
            
            self.errorPresenter.presentError(from: alertPresentingViewController, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.dismissQRCodeScanningIfPresented(animated: false)
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
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
        
        if let qrCodeReaderViewController = self.qrCodeReaderViewController {
            qrCodeReaderViewController.present(alert, animated: animated, completion: nil)
        }
    }
    
    private func checkCameraAccessAndPresentQRCodeReader(animated: Bool) {
        guard self.cameraAccessManager.isCameraAvailable else {
            self.cameraAccessAlertPresenter.presentCameraUnavailableAlert(from: self, animated: animated)
            return
        }
        
        self.cameraAccessManager.askAndRequestCameraAccessIfNeeded { (granted) in
            if granted {
                self.presentQRCodeReader(animated: animated)
            } else {
                self.cameraAccessAlertPresenter.presentPermissionDeniedAlert(from: self, animated: animated)
            }
        }
    }
    
    private func stopQRCodeScanningIfPresented() {
        guard let qrCodeReaderViewController = self.qrCodeReaderViewController else {
            return
        }
        qrCodeReaderViewController.view.isUserInteractionEnabled = false
        qrCodeReaderViewController.stopScanning()
    }
    
    private func dismissQRCodeScanningIfPresented(animated: Bool, completion: (() -> Void)? = nil) {
        guard self.qrCodeReaderViewController?.presentingViewController != nil else {
            return
        }
        self.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Actions

    @IBAction private func scanButtonAction(_ sender: Any) {
        self.checkCameraAccessAndPresentQRCodeReader(animated: true)
    }
    
    @IBAction private func cannotScanAction(_ sender: Any) {
        self.viewModel.process(viewAction: .cannotScan)
    }
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .cancel)
    }
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - KeyVerificationVerifyByScanningViewModelViewDelegate
extension KeyVerificationVerifyByScanningViewController: KeyVerificationVerifyByScanningViewModelViewDelegate {

    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyByScanningViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - QRCodeReaderViewControllerDelegate
extension KeyVerificationVerifyByScanningViewController: QRCodeReaderViewControllerDelegate {
    
    func qrCodeReaderViewController(_ viewController: QRCodeReaderViewController, didFound payloadData: Data) {        
        self.viewModel.process(viewAction: .scannedCode(payloadData: payloadData))
    }
    
    func qrCodeReaderViewControllerDidCancel(_ viewController: QRCodeReaderViewController) {
        self.dismissQRCodeScanningIfPresented(animated: true)
    }
}
