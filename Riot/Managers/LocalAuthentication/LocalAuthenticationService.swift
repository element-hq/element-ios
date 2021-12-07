// 
// Copyright 2020 Vector Creations Ltd
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
