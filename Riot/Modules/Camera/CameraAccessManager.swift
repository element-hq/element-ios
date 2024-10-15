/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// CameraAccessManager handles camera availability and authorization.
final class CameraAccessManager {
    
    // MARK: - Properties
    
    var isCameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var isCameraAccessGranted: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    // MARK: - Public
        
    func askAndRequestCameraAccessIfNeeded(completion: @escaping (_ granted: Bool) -> Void) {
        
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            self.requestCameraAccess(completion: { (granted) in
                completion(granted)
            })
        case .denied, .restricted:
            completion(false)
        @unknown default:
            break
        }
    }

    /// Checks and requests the camera access if needed. Returns `true` if granted, otherwise `false`.
    func requestCameraAccessIfNeeded() async -> Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Private
    
    private func requestCameraAccess(completion: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
