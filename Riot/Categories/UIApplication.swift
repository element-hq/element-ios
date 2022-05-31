/*
 Copyright 2019 New Vector Ltd
 
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

extension UIApplication {
    @objc func vc_open(_ url: URL, completionHandler completion: ((_ success: Bool) -> Void)? = nil) {
        
        let application = UIApplication.shared
        
        guard application.canOpenURL(url) else {
            completion?(false)
            return
        }
        
        application.open(url, options: [:], completionHandler: { success in
            completion?(success)
        })
    }
    
    /// Attempts to resign the first responder in the app. This method can be used when the first responder is not known.
    /// - Returns: true if a responder object handled the resignation, false otherwise.
    @objc @discardableResult func vc_closeKeyboard() -> Bool {
        return sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Open system application settings
    func vc_openSettings(completion: ((Bool) -> Void)? = nil) {
        guard let applicationSettingsURL = URL(string: UIApplication.openSettingsURLString) else {
            completion?(false)
            return
        }
        UIApplication.shared.open(applicationSettingsURL, completionHandler: completion)
    }
}
