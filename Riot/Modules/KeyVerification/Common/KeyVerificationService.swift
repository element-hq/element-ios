/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyVerificationService {
    
    private let cameraAccessManager: CameraAccessManager
        
    private var supportSetupKeyVerificationByUser: [String: Bool] = [:] // Cached server response
    
    init() {
        self.cameraAccessManager = CameraAccessManager()
    }
    
    func supportedKeyVerificationMethods() -> [String] {
        var supportedMethods: [String] = [
            MXKeyVerificationMethodSAS,
            MXKeyVerificationMethodQRCodeShow,
            MXKeyVerificationMethodReciprocate
        ]
        
        if self.cameraAccessManager.isCameraAvailable {
            supportedMethods.append(MXKeyVerificationMethodQRCodeScan)
        }
        
        return supportedMethods
    }
}
