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
    
    // MARK: - Private
    
    private func requestCameraAccess(completion: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
