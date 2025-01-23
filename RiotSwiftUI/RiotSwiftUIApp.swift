//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
