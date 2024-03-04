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
        
        let angleRadius = captureRotation / 180.0 * Double.pi
        let captureTransform = CGAffineTransform(rotationAngle: CGFloat(angleRadius))
        
        zxCapture.transform = captureTransform
        zxCapture.rotation = CGFloat(scanRectRotation)
        zxCapture.layer.frame = self.bounds
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
