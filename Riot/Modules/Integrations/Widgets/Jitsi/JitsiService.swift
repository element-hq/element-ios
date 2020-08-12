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

#if canImport(JitsiMeet)
import JitsiMeet

/// JitsiService enables to abstract and configure Jitsi Meet SDK
@objcMembers
final class JitsiService: NSObject {
    
    static let shared = JitsiService()
    
    // MARK: - Properties
    
    var enableCallKit: Bool = true {
        didSet {
            JMCallKitProxy.enabled = enableCallKit
        }
    }

    var serverURL: URL? {
        return self.jitsiMeet.defaultConferenceOptions?.serverURL
    }

    private let jitsiMeet = JitsiMeet.sharedInstance()
    
    // MARK: - Setup
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public
    
    // MARK: Configuration
    
    func configureDefaultConferenceOptions(with serverURL: URL) {
        self.jitsiMeet.defaultConferenceOptions = JitsiMeetConferenceOptions.fromBuilder({ (builder) in
            builder.serverURL = serverURL
        })
    }
    
    func configureCallKitProvider(localizedName: String, ringtoneName: String?, iconTemplateImageData: Data?) {
        JMCallKitProxy.configureProvider(localizedName: localizedName, ringtoneSound: ringtoneName, iconTemplateImageData: iconTemplateImageData)
    }
    
    // MARK: AppDelegate methods
    
    @discardableResult
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return self.jitsiMeet.application(application, didFinishLaunchingWithOptions: launchOptions ?? [:])
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return self.jitsiMeet.application(application, open: url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return self.jitsiMeet.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
}
#endif
