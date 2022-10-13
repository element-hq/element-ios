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
    private let sessionCreator: SessionCreatorProtocol
    private var isCameraReady = false
    private lazy var zxCapture = ZXCapture()

    private let cameraAccessManager = CameraAccessManager()
    
    private var rendezvousService: RendezvousService?

    init(client: AuthenticationRestClient,
         mode: QRLoginServiceMode,
         state: QRLoginServiceState = .initial) {
        self.client = client
        self.sessionCreator = SessionCreator()
        self.mode = mode
        self.state = state
        super.init()
    }

    // MARK: QRLoginServiceProtocol

    let mode: QRLoginServiceMode

    var state: QRLoginServiceState {
        didSet {
            if state != oldValue {
                callbacks.send(.didUpdateState)
            }
        }
    }

    let callbacks = PassthroughSubject<QRLoginServiceCallback, Never>()

    func isServiceAvailable() async throws -> Bool {
        switch mode {
        case .authenticated:
            guard BuildSettings.qrLoginEnabledFromAuthenticated else {
                return false
            }
        case .notAuthenticated:
            guard BuildSettings.qrLoginEnabledFromNotAuthenticated else {
                return false
            }
        }
        return try await client.supportedMatrixVersions().supportsQRLogin
    }

    func canDisplayQR() -> Bool {
        BuildSettings.qrLoginEnableDisplayingQRs
    }

    func generateQRCode() async throws -> QRLoginCode {
        fatalError("Not implemented")
    }
    
    func scannerView() -> AnyView {
        let frame = UIScreen.main.bounds
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
        zxCapture.delegate = nil
        
        guard zxCapture.running else {
            return
        }

        if destroy {
            zxCapture.hard_stop()
        } else {
            zxCapture.stop()
        }
    }

    @MainActor
    func processScannedQR(_ data: Data) {
        guard let code = try? JSONDecoder().decode(QRLoginCode.self, from: data) else {
            state = .failed(error: .invalidQR)
            return
        }
        
        Task {
            await processQRLoginCode(code)
        }
    }

    func confirmCode() {
        switch state {
        case .waitingForConfirmation:
            // TODO: implement
            break
        default:
            return
        }
    }

    func restart() {
        state = .initial
        
        Task {
            await declineRendezvous()
        }
    }

    func reset() {
        stopScanning(destroy: false)
        state = .initial
        
        Task {
            await declineRendezvous()
        }
    }

    deinit {
        stopScanning(destroy: true)
    }

    // MARK: Private
    
    @MainActor
    private func processQRLoginCode(_ code: QRLoginCode) async {
        MXLog.debug("[QRLoginService] processQRLoginCode: \(code)")
        state = .connectingToDevice
        
        guard let uri = code.rendezvous.transport?.uri,
              let rendezvousURL = URL(string: uri),
              let key = code.rendezvous.key else {
            MXLog.debug("[QRLoginService] QR code invalid")
            state = .failed(error: .invalidQR)
            return
        }
        
        let transport = RendezvousTransport(baseURL: BuildSettings.rendezvousServerBaseURL,
                                            rendezvousURL: rendezvousURL)
        let rendezvousService = RendezvousService(transport: transport)
        self.rendezvousService = rendezvousService
        
        MXLog.debug("[QRLoginService] Joining the rendezvous at \(rendezvousURL)")
        guard case .success(let validationCode) = await rendezvousService.joinRendezvous(withPublicKey: key) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        state = .waitingForConfirmation(validationCode)
        
        // TODO: check compatibility of intents
        
        MXLog.debug("[QRLoginService] Waiting for available protocols")
        guard case let .success(data) = await rendezvousService.receive(),
              let responsePayload = try? JSONDecoder().decode(QRLoginRendezvousPayload.self, from: data) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Received available protocols \(responsePayload)")
        guard let protocols = responsePayload.protocols,
              protocols.contains(.loginToken) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Request login with `login_token`")
        guard let requestData = try? JSONEncoder().encode(QRLoginRendezvousPayload(type: .loginProgress, protocol: .loginToken)),
              case .success = await rendezvousService.send(data: requestData) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Waiting for the login token")
        guard case let .success(data) = await rendezvousService.receive(),
              let responsePayload = try? JSONDecoder().decode(QRLoginRendezvousPayload.self, from: data),
              let login_token = responsePayload.loginToken else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        MXLog.debug("[QRLoginService] Received login token \(responsePayload)")
        
        state = .waitingForRemoteSignIn
        
        MXLog.debug("[QRLoginService] Logging in with the login token")
        guard let credentials = try? await client.login(parameters: LoginTokenParameters(token: login_token)) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        MXLog.debug("[QRLoginService] Got acess token")
        
        let session = sessionCreator.createSession(credentials: credentials, client: client, removeOtherAccounts: false)
        
        MXLog.debug("[QRLoginService] Session created without E2EE support. Inform the interlocutor of finishing")
        guard let requestData = try? JSONEncoder().encode(QRLoginRendezvousPayload(type: .loginFinish, outcome: .success)),
              case .success = await rendezvousService.send(data: requestData) else {
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        state = .completed(session: session)
    }
    
    private func declineRendezvous() async {
        guard let requestData = try? JSONEncoder().encode(QRLoginRendezvousPayload(type: .loginFinish, outcome: .declined)) else {
            return
        }
        
        _ = await rendezvousService?.send(data: requestData)
        
        await teardownRendezvous()
    }
    
    private func teardownRendezvous(state: QRLoginServiceState? = nil) async {
        // Stop listening for changes, try deleting the resource
        _ = await rendezvousService?.tearDown()
        
        // Try setting the new state, if necessary
        if let state = state {
            switch self.state {
            case .completed:
                return
            case .initial:
                return
            default:
                self.state = state
            }
        }
    }
}

// MARK: - ZXCaptureDelegate

extension QRLoginService: ZXCaptureDelegate {
    func captureCameraIsReady(_ capture: ZXCapture!) {
        isCameraReady = true
    }

    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        guard isCameraReady,
              let result = result,
              result.barcodeFormat == kBarcodeFormatQRCode else {
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
