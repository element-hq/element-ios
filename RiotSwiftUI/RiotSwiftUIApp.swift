//
// Copyright 2021 New Vector Ltd
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
import SwiftUI

@main
/// RiotSwiftUI screens rendered for UI Tests.
struct RiotSwiftUIApp: App {
    @UIApplicationDelegateAdaptor private var delegate: RiotSwiftUIAppDelegate
    
    init() {
        UILog.configure(logger: PrintLogger.self)
        
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark:
            ThemePublisher.configure(themeId: .dark)
        default:
            ThemePublisher.configure(themeId: .light)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ScreenList(screens: MockAppScreens.appScreens)
        }
    }
}

class RiotSwiftUIAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if ProcessInfo.processInfo.environment["IS_RUNNING_UI_TESTS"] == "1" {
            UIView.setAnimationsEnabled(false)
        }
        
        return true
    }
}
