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
import ZXingObjC

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
    
    private lazy var zxCapture: ZXCapture = ZXCapture()
    private var captureSizeTransform: CGAffineTransform?
    private var isScanning: Bool = false
    private var isFirstApplyOrientation: Bool = false
    
    // MARK: Public
    
    weak var delegate: QRCodeReaderViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> QRCodeReaderViewController {
        let viewController = StoryboardScene.QRCodeReaderViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    deinit {
        self.zxCapture.layer.removeFromSuperlayer()
        self.zxCapture.hard_stop()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard isFirstApplyOrientation == false else {
            return
        }
        
        isFirstApplyOrientation = true
        applyOrientation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // do nothing
        }, completion: { [weak self] (context) in
            guard let self = self else {
                return
            }
            self.applyOrientation()
        })
    }
    
    // MARK: - Public
    
    func startScanning() {
        self.zxCapture.start()
        isScanning = true
    }
    
    func stopScanning() {
        self.zxCapture.stop()
        isScanning = false
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
        self.setupQRCodeReaderView()
    }
    
    private func setupQRCodeReaderView() {
        zxCapture.delegate = self
        zxCapture.camera = zxCapture.back()
        
        zxCapture.layer.frame = codeReaderContainerView.bounds
        codeReaderContainerView.layer.addSublayer(zxCapture.layer)
    }
    
    private func applyOrientation() {
        
        let orientation = UIApplication.shared.statusBarOrientation
        let captureRotation: Double
        let scanRectRotation: Double
        
        switch orientation {
        case .portrait:
            captureRotation = 0
            scanRectRotation = 90
        case .landscapeLeft:
            captureRotation = 90
            scanRectRotation = 180
        case .landscapeRight:
            captureRotation = 270
            scanRectRotation = 0
        case .portraitUpsideDown:
            captureRotation = 180
            scanRectRotation = 270
        default:
            captureRotation = 0
            scanRectRotation = 90
        }
        
        applyRectOfInterest(orientation: orientation)
        
        let angleRadius = captureRotation / 180.0 * Double.pi
        let captureTranform = CGAffineTransform(rotationAngle: CGFloat(angleRadius))
        
        zxCapture.transform = captureTranform
        zxCapture.rotation = CGFloat(scanRectRotation)
        zxCapture.layer.frame = codeReaderContainerView.frame
    }
    
    private func applyRectOfInterest(orientation: UIInterfaceOrientation) {
        guard var transformedVideoRect = codeReaderContainerView?.frame,
            let cameraSessionPreset = zxCapture.sessionPreset
            else { return }
        
        var scaleVideoX, scaleVideoY: CGFloat
        var videoHeight, videoWidth: CGFloat
        
        // Currently support only for 1920x1080 || 1280x720
        if cameraSessionPreset == AVCaptureSession.Preset.hd1920x1080.rawValue {
            videoHeight = 1080.0
            videoWidth = 1920.0
        } else {
            videoHeight = 720.0
            videoWidth = 1280.0
        }
        
        if orientation == UIInterfaceOrientation.portrait {
            scaleVideoX = self.view.frame.width / videoHeight
            scaleVideoY = self.view.frame.height / videoWidth
            
            // Convert CGPoint under portrait mode to map with orientation of image
            // because the image will be cropped before rotate
            // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
            let realX = transformedVideoRect.origin.y
            let realY = self.view.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x
            let realWidth = transformedVideoRect.size.height
            let realHeight = transformedVideoRect.size.width
            transformedVideoRect = CGRect(x: realX, y: realY, width: realWidth, height: realHeight)
            
        } else {
            scaleVideoX = self.view.frame.width / videoWidth
            scaleVideoY = self.view.frame.height / videoHeight
        }
        
        captureSizeTransform = CGAffineTransform(scaleX: 1.0/scaleVideoX, y: 1.0/scaleVideoY)
        
        guard let _captureSizeTransform = captureSizeTransform else {
            return
        }
        
        let transformRect = transformedVideoRect.applying(_captureSizeTransform)
        zxCapture.scanRect = transformRect
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.qrCodeReaderViewControllerDidCancel(self)
    }
}

// MARK: - ZXCaptureDelegate
extension QRCodeReaderViewController: ZXCaptureDelegate {
    
    func captureCameraIsReady(_ capture: ZXCapture!) {
        isScanning = true
    }
    
    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        guard let zxResult = result, isScanning == true else {
            return
        }
        
        guard zxResult.barcodeFormat == kBarcodeFormatQRCode else {
            return
        }
        
        self.stopScanning()
        
        if let bytes = result.resultMetadata.object(forKey: kResultMetadataTypeByteSegments.rawValue) as? NSArray,
            let byteArray = bytes.firstObject as? ZXByteArray {
            
            let data = Data(bytes: UnsafeRawPointer(byteArray.array), count: Int(byteArray.length))
            
            self.delegate?.qrCodeReaderViewController(self, didFound: data)
        }
    }
}
