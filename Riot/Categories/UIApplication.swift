/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
