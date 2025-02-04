//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Foundation
import MatrixSDK
import SwiftUI
import ZXingObjC

// MARK: - QRLoginService

// n.b MSC3886/MSC3903/MSC3906 that this is based on are now closed.
// However, we want to keep this implementation around for some time.
// TODO: define an end-of-life date for this implementation.
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
        sessionCreator = SessionCreator()
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
        if (zxCapture.delegate != nil) {
            // Setting the zxCapture to nil without checking makes it start
            // scanning and implicitly requesting camera access
            zxCapture.delegate = nil
        }
        
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

        // we check these first so that we can show a more specific error message
        guard code.rendezvous.transport?.type == "org.matrix.msc3886.http.v1",
              let algorithm = RendezvousChannelAlgorithm(rawValue: code.rendezvous.algorithm) else {
            MXLog.error("[QRLoginService] Unsupported algorithm or transport")
            state = .failed(error: .deviceNotSupported)
            return
        }

        guard let flow = code.flow != nil ? RendezvousFlow(rawValue: code.flow!) : .SETUP_ADDITIONAL_DEVICE_V1 else {
            MXLog.error("[QRLoginService] Unsupported flow")
            state = .failed(error: .deviceNotSupported)
            return
        }

        // so, this is of an expected algorithm so any bad data can be considered an invalid QR code
        guard code.intent == QRLoginRendezvousPayload.Intent.loginReciprocate.rawValue,
              let uri = code.rendezvous.transport?.uri,
              let rendezvousURL = URL(string: uri),
              let key = code.rendezvous.key else {
            MXLog.error("[QRLoginService] QR code invalid")
            state = .failed(error: .invalidQR)
            return
        }
        
        state = .connectingToDevice

        let transport = RendezvousTransport(baseURL: BuildSettings.rendezvousServerBaseURL,
                                            rendezvousURL: rendezvousURL)
        let rendezvousService = RendezvousService(transport: transport, algorithm: algorithm)
        self.rendezvousService = rendezvousService
        
        MXLog.debug("[QRLoginService] Joining the rendezvous at \(rendezvousURL)")
        guard case .success(let validationCode) = await rendezvousService.joinRendezvous(withPublicKey: key) else {
            MXLog.error("[QRLoginService] Failed joining rendezvous")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        state = .waitingForConfirmation(validationCode)
        
        MXLog.debug("[QRLoginService] Waiting for available protocols")
        guard case let .success(data) = await rendezvousService.receive(),
              let responsePayload = try? JSONDecoder().decode(QRLoginRendezvousPayload.self, from: data) else {
            MXLog.error("[QRLoginService] Failed receiving available protocols")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Received available protocols \(responsePayload)")
        guard let protocols = responsePayload.protocols,
              protocols.contains(.loginToken) else {
            MXLog.error("[QRLoginService] Unexpected protocols, cannot continue")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Request login with `login_token`")
        let protocolPayload = flow == .SETUP_ADDITIONAL_DEVICE_V1
            ? QRLoginRendezvousPayload(type: .loginProgress, protocol: .loginToken)
            : QRLoginRendezvousPayload(type: .loginProtocol, protocol: .loginToken)
        guard let requestData = try? JSONEncoder().encode(protocolPayload),
              case .success = await rendezvousService.send(data: requestData) else {
            MXLog.error("[QRLoginService] Failed sending continue with `login_token` request")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Waiting for the login token")
        guard case let .success(data) = await rendezvousService.receive(),
              let responsePayload = try? JSONDecoder().decode(QRLoginRendezvousPayload.self, from: data),
              let login_token = responsePayload.loginToken,
              let homeserver = responsePayload.homeserver,
              let homeserverURL  = URL(string: homeserver) else {
            MXLog.error("[QRLoginService] Invalid login details")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        MXLog.debug("[QRLoginService] Received login token \(responsePayload)")
        
        state = .waitingForRemoteSignIn
        
        // Use a custom rest client linked to the existing device's homeserver
        let authenticationRestClient = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        MXLog.debug("[QRLoginService] Logging in with the login token")
        guard let credentials = try? await authenticationRestClient.login(parameters: LoginTokenParameters(token: login_token)) else {
            MXLog.error("[QRLoginService] Failed logging in with the login token")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Got acess token")
        
        let session = await createSession(credentials: credentials, client: client)
        
        MXLog.debug("[QRLoginService] Session created, sending device details")
        let successPayload = flow == .SETUP_ADDITIONAL_DEVICE_V1
            ? QRLoginRendezvousPayload(type: .loginProgress, outcome: .success, deviceId: session.myDeviceId, deviceKey: session.crypto.deviceEd25519Key)
            : QRLoginRendezvousPayload(type: .loginSuccess, deviceId: session.myDeviceId, deviceKey: session.crypto.deviceEd25519Key)

        guard let requestData = try? JSONEncoder().encode(successPayload),
              case .success = await rendezvousService.send(data: requestData) else {
            MXLog.error("[QRLoginService] Failed sending session details")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        // explicitly download keys for ourself rather than racing with initial sync which might not complete in time
        MXLog.debug("[QRLoginService] Downloading device list for self")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.crypto.downloadKeys([session.myUserId], forceDownload: false) { _, _ in
                MXLog.debug("[QRLoginService] Device list downloaded for self")
                continuation.resume(returning: ())
            } failure: { _ in
                MXLog.error("[QRLoginService] Failed to download the device list for self")
                continuation.resume(returning: ())
            }
        }
        
        MXLog.debug("[QRLoginService] Wait for cross-signing details")
        guard case let .success(data) = await rendezvousService.receive(),
              let responsePayload = try? JSONDecoder().decode(QRLoginRendezvousPayload.self, from: data),
              flow == .SETUP_ADDITIONAL_DEVICE_V1 && responsePayload.outcome == .verified || responsePayload.type == .loginVerified,
              let verifiyingDeviceId = responsePayload.verifyingDeviceId,
              let verifyingDeviceKey = responsePayload.verifyingDeviceKey else {
            MXLog.error("[QRLoginService] Received invalid cross-signing details")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Received cross-signing details \(responsePayload)")
        
        if let masterKeyFromVerifyingDevice = responsePayload.masterKey,
           let localMasterKey = session.crypto.crossSigning.crossSigningKeys(forUser: session.myUserId)?.masterKeys?.keys {
            guard masterKeyFromVerifyingDevice == localMasterKey else {
                MXLog.error("[QRLoginService] Received invalid master key from verifying device")
                await teardownRendezvous(state: .failed(error: .rendezvousFailed))
                return
            }
            
            MXLog.debug("[QRLoginService] Marking the received master key as trusted")
            let mskVerificationResult = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                session.crypto.setUserVerification(true, forUser: session.myUserId) {
                    MXLog.debug("[QRLoginService] Successfully marked the received master key as trusted")
                    continuation.resume(returning: true)
                } failure: { error in
                    continuation.resume(returning: false)
                }
            }
            
            guard mskVerificationResult == true else {
                MXLog.error("[QRLoginService] Failed marking the master key as trusted")
                await teardownRendezvous(state: .failed(error: .rendezvousFailed))
                return
            }
        }
        
        guard let verifyingDeviceInfo = session.crypto.device(withDeviceId: verifiyingDeviceId, ofUser: session.myUserId),
              verifyingDeviceInfo.fingerprint == verifyingDeviceKey else {
            MXLog.error("[QRLoginService] Received invalid verifying device info")
            await teardownRendezvous(state: .failed(error: .rendezvousFailed))
            return
        }
        
        MXLog.debug("[QRLoginService] Locally marking the existing device as verified \(verifyingDeviceInfo)")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.crypto.setDeviceVerification(.verified, forDevice: verifiyingDeviceId, ofUser: session.myUserId) {
                MXLog.debug("[QRLoginService] Marked the existing device as verified")
                continuation.resume(returning: ())
            } failure: { _ in
                MXLog.error("[QRLoginService] Failed marking the existing device as verified")
                continuation.resume(returning: ())
            }
        }

        MXLog.debug("[QRLoginService] Login flow finished, returning session")
        state = .completed(session: session, securityCompleted: true)
    }
    
    private func createSession(credentials: MXCredentials, client: AuthenticationRestClient) async -> MXSession {
        let session = await sessionCreator.createSession(credentials: credentials, client: client, removeOtherAccounts: false)
        
        if session.state == .storeDataReady {
            return session
        }
        
        await withCheckedContinuation { continuation in
            NotificationCenter.default.addObserver(forName: NSNotification.Name.mxSessionStateDidChange, object: session, queue: nil) { notification in
                guard let session = notification.object as? MXSession else {
                    fatalError()
                }
                
                if session.state == .storeDataReady {
                    continuation.resume()
                }
            }
        }
        
        return session
    }
    
    private func declineRendezvous() async {
        guard let requestData = try? JSONEncoder().encode(QRLoginRendezvousPayload(type: .loginFinish, outcome: .declined)) else {
            return
        }
        
        _ = await rendezvousService?.send(data: requestData)
        
        await teardownRendezvous()
    }
    
    @MainActor
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
