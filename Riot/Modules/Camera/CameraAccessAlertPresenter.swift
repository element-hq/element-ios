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

final class CameraAccessAlertPresenter {
        
    // MARK: - Public
    
    func presentPermissionDeniedAlert(from presentingViewController: UIViewController, animated: Bool) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        let appDisplayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
        
        let alert = UIAlertController(title: VectorL10n.camera, message: VectorL10n.cameraAccessNotGranted(appDisplayName), preferredStyle: .alert)
        
        let cancelActionTitle = VectorL10n.ok
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel)
        
        let settingsActionTitle = VectorL10n.settings
        let settingsAction = UIAlertAction(title: settingsActionTitle, style: .default, handler: { _ in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: { (succeed) in
                if !succeed {
                    MXLog.debug("[CameraPresenter] Fails to open settings")
                }
            })
        })
        
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        
        presentingViewController.present(alert, animated: animated, completion: nil)
    }
    
    func presentCameraUnavailableAlert(from presentingViewController: UIViewController, animated: Bool) {
        
        let alert = UIAlertController(title: VectorL10n.camera, message: VectorL10n.cameraUnavailable, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: VectorL10n.accept, style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        presentingViewController.present(alert, animated: true, completion: nil)
    }
}
