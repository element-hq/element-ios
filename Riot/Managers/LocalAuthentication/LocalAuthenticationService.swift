// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class LocalAuthenticationService: NSObject {
    
    private let pinCodePreferences: PinCodePreferences
    
    init(pinCodePreferences: PinCodePreferences) {
        self.pinCodePreferences = pinCodePreferences
        super.init()
        
        setup()
    }
    
    private var appLastActiveTime: TimeInterval?
    
    private var systemUptime: TimeInterval {
        var uptime = timespec()
        if 0 != clock_gettime(CLOCK_MONOTONIC_RAW, &uptime) {
            fatalError("Could not execute clock_gettime, errno: \(errno)")
        }

        return TimeInterval(uptime.tv_sec)
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    var shouldShowPinCode: Bool {
        if !pinCodePreferences.isPinSet && !pinCodePreferences.isBiometricsSet {
            return false
        }
        if MXKAccountManager.shared()?.activeAccounts.count == 0 {
            return false
        }
        guard let appLastActiveTime = appLastActiveTime else {
            return true
        }
        return (systemUptime - appLastActiveTime) >= pinCodePreferences.graceTimeInSeconds
    }
    
    var isProtectionSet: Bool {
        return pinCodePreferences.isPinSet || pinCodePreferences.isBiometricsSet
    }

    func applicationWillResignActive() {
        appLastActiveTime = systemUptime
    }
    
    func shouldLogOutUser() -> Bool {
        if BuildSettings.logOutUserWhenPINFailuresExceeded && pinCodePreferences.numberOfPinFailures >= pinCodePreferences.maxAllowedNumberOfPinFailures {
            return true
        }
        if BuildSettings.logOutUserWhenBiometricsFailuresExceeded && pinCodePreferences.numberOfBiometricsFailures >= pinCodePreferences.maxAllowedNumberOfBiometricsFailures {
            return true
        }
        return false
    }

}
