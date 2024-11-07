/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol QRCodeReaderViewControllerDelegate: AnyObject {
    func qrCodeReaderViewController(_ viewController: QRCodeReaderViewController, didFound payloadData: Data)
    func qrCodeReaderViewControllerDidCancel(_ viewController: QRCodeReaderViewController)
}

/// QRCodeReaderViewController is a view controller used to scan a QR code
/// Some methods are based on [ZXing sample](https://github.com/zxingify/zxingify-objc/blob/master/examples/BarcodeScannerSwift/BarcodeScannerSwift/ViewController.swift)
final class QRCodeReaderViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var closeButton: CloseButton!
    @IBOutlet private weak var codeReaderContainerView: UIView!
    
    // MARK: Private
    
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    
    private var qrCodeReaderView: QRCodeReaderView!
    
    // MARK: Public
    
    weak var delegate: QRCodeReaderViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> QRCodeReaderViewController {
        let viewController = StoryboardScene.QRCodeReaderViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
        
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.startScanning()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        self.stopScanning()
        
        super.viewWillDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Public
    
    func startScanning() {
        qrCodeReaderView.startScanning()
    }
    
    func stopScanning() {
        qrCodeReaderView.stopScanning()
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.closeButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let qrCodeReaderView = QRCodeReaderView()
        qrCodeReaderView.didFoundData = qrCodeReader(didFound:)
        self.qrCodeReaderView = qrCodeReaderView
        
        self.codeReaderContainerView.vc_addSubViewMatchingParent(qrCodeReaderView)
    }
    
    private func qrCodeReader(didFound data: Data) {
        self.delegate?.qrCodeReaderViewController(self, didFound: data)
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.qrCodeReaderViewControllerDidCancel(self)
    }
}
