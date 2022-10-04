//
// Copyright 2022 New Vector Ltd
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

import AVFoundation
import Combine
import Foundation
import MatrixSDK
import SwiftUI
import ZXingObjC

// MARK: - QRLoginService

class QRLoginService: NSObject, QRLoginServiceProtocol {
    private let client: AuthenticationRestClient
    private var isCameraReady = false
    private lazy var zxCapture = ZXCapture()

    private let cameraAccessManager = CameraAccessManager()

    init(client: AuthenticationRestClient) {
        self.client = client
        super.init()
    }

    // MARK: QRLoginServiceProtocol

    var state: QRLoginServiceState = .initial {
        didSet {
            if state != oldValue {
                callbacks.send(.didUpdateState)
            }
        }
    }

    let callbacks = PassthroughSubject<QRLoginServiceCallback, Never>()

    func isServiceAvailable() async throws -> Bool {
        guard BuildSettings.enableQRLogin else {
            return false
        }
        return try await client.supportedMatrixVersions().supportsQRLogin
    }

    func generateQRCode() async throws -> QRLoginCode {
        let transport = QRLoginRendezvousTransportDetails(type: "http.v1",
                                                          uri: "")
        let rendezvous = QRLoginRendezvous(transport: transport,
                                           algorithm: "m.rendezvous.v1.curve25519-aes-sha256",
                                           key: "")
        return QRLoginCode(user: client.credentials.userId,
                           initiator: .new,
                           rendezvous: rendezvous)
    }

    func scannerView() -> AnyView {
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let view = UIView(frame: frame)
        zxCapture.layer.frame = frame
        view.layer.addSublayer(zxCapture.layer)
        return AnyView(ViewWrapper(view: view))
    }

    func startScanning() {
        Task { @MainActor in
            if cameraAccessManager.isCameraAvailable {
                let granted = await cameraAccessManager.requestCameraAccessIfNeeded()
                if granted {
                    state = .scanningQR
                    zxCapture.delegate = self
                    zxCapture.camera = zxCapture.back()
                    zxCapture.start()
                } else {
                    state = .failed(error: .noCameraAccess)
                }
            } else {
                state = .failed(error: .noCameraAvailable)
            }
        }
    }

    func stopScanning(destroy: Bool) {
        guard zxCapture.running else {
            return
        }

        if destroy {
            zxCapture.hard_stop()
        } else {
            zxCapture.stop()
        }
    }

    func processScannedQR(_ data: Data) {
        state = .processingQR
        do {
            let code = try JSONDecoder().decode(QRLoginCode.self, from: data)
            MXLog.debug("[QRLoginService] processScannedQR: \(code)")
            // TODO: implement
        } catch {
            state = .failed(error: .invalidQR)
        }
    }

    deinit {
        stopScanning(destroy: true)
    }

    // MARK: Private
}

// MARK: - ZXCaptureDelegate

extension QRLoginService: ZXCaptureDelegate {
    func captureCameraIsReady(_ capture: ZXCapture!) {
        isCameraReady = true
    }

    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        guard let zxResult = result, isCameraReady == true else {
            return
        }

        guard zxResult.barcodeFormat == kBarcodeFormatQRCode else {
            return
        }

        stopScanning(destroy: false)

        if let bytes = result.resultMetadata.object(forKey: kResultMetadataTypeByteSegments.rawValue) as? NSArray,
           let byteArray = bytes.firstObject as? ZXByteArray {
            let data = Data(bytes: UnsafeRawPointer(byteArray.array), count: Int(byteArray.length))

            callbacks.send(.didScanQR(data))
        }
    }
}

// MARK: - ViewWrapper

private struct ViewWrapper: UIViewRepresentable {
    var view: UIView

    func makeUIView(context: Context) -> some UIView {
        view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
