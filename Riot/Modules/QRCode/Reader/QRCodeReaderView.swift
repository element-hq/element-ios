// 
// Copyright 2023 New Vector Ltd
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
import ZXingObjC
import Combine

final class QRCodeReaderView: UIView {
    
    // MARK: Public
    
    var didFoundData: (Data) -> Void = { _ in }
    
    // MARK: Private
    
    private lazy var zxCapture: ZXCapture = ZXCapture()
    private var captureSizeTransform: CGAffineTransform?
    private var isScanning: Bool = false
    private var isFirstApplyOrientation: Bool = false

    private var rotationObserver: AnyCancellable?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
#if !targetEnvironment(simulator)
        self.zxCapture.layer.removeFromSuperlayer()
        self.zxCapture.hard_stop()
#endif
    }
        
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            stopScanning()
        }
    }
    
    // MARK: - Public
    
    func startScanning() {
#if !targetEnvironment(simulator)
        self.zxCapture.start()
#endif
        isScanning = true
    }
    
    func stopScanning() {
#if !targetEnvironment(simulator)
        self.zxCapture.stop()
#endif
        isScanning = false
    }
    
    //  MARK: - Private
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard isFirstApplyOrientation == false else {
            return
        }
        
        isFirstApplyOrientation = true
        applyOrientation()
    }
    
    private func setup() {
        isUserInteractionEnabled = true
        clipsToBounds = true
        self.setupQRCodeReaderView()
        
        rotationObserver = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink(receiveValue: { [weak self] _ in
                self?.applyOrientation()
            })
    }
    
    private func setupQRCodeReaderView() {
#if !targetEnvironment(simulator)
        zxCapture.delegate = self
        zxCapture.camera = zxCapture.back()
        zxCapture.layer.frame = self.bounds
        self.layer.addSublayer(zxCapture.layer)
#endif
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
        zxCapture.layer.frame = self.bounds
    }
    
    private func applyRectOfInterest(orientation: UIInterfaceOrientation) {
        var transformedVideoRect = self.frame
        let cameraSessionPreset = zxCapture.sessionPreset
        
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
            scaleVideoX = self.frame.width / videoHeight
            scaleVideoY = self.frame.height / videoWidth
            
            // Convert CGPoint under portrait mode to map with orientation of image
            // because the image will be cropped before rotate
            // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
            let realX = transformedVideoRect.origin.y
            let realY = self.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x
            let realWidth = transformedVideoRect.size.height
            let realHeight = transformedVideoRect.size.width
            transformedVideoRect = CGRect(x: realX, y: realY, width: realWidth, height: realHeight)
            
        } else {
            scaleVideoX = self.frame.width / videoWidth
            scaleVideoY = self.frame.height / videoHeight
        }
        
        captureSizeTransform = CGAffineTransform(scaleX: 1.0/scaleVideoX, y: 1.0/scaleVideoY)
        
        guard let _captureSizeTransform = captureSizeTransform else {
            return
        }
        
        let transformRect = transformedVideoRect.applying(_captureSizeTransform)
        zxCapture.scanRect = transformRect
    }
}


// MARK: - ZXCaptureDelegate
extension QRCodeReaderView: ZXCaptureDelegate {
    
    func captureCameraIsReady(_ capture: ZXCapture!) {
        startScanning()
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
            
            self.didFoundData(data)
        }
    }
}
