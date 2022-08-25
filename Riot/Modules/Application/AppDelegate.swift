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

import PushKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Properties

    // MARK: Private

    private var appCoordinator: AppCoordinatorType!
    private var rootRouter: RootRouterType!

    private var legacyAppDelegate: LegacyAppDelegate {
        AppDelegate.theDelegate()
    }
    
    // MARK: Public
    
    /// Call the Riot legacy AppDelegate
    @objc class func theDelegate() -> LegacyAppDelegate {
        guard let legacyAppDelegate = LegacyAppDelegate.the() else {
            fatalError("[AppDelegate] theDelegate property should not be nil")
        }
        return legacyAppDelegate
    }
    
    // UIApplicationDelegate properties
    
    /// Main application window
    var window: UIWindow?
    
    // MARK: - UIApplicationDelegate
    
    // MARK: Life cycle
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        legacyAppDelegate.application(application, willFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup window
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        // Create AppCoordinator
        rootRouter = RootRouter(window: window)
        
        let appCoordinator = AppCoordinator(router: rootRouter, window: window)
        appCoordinator.start()
        legacyAppDelegate.delegate = appCoordinator
        
        self.appCoordinator = appCoordinator
        
        // Call legacy AppDelegate
        legacyAppDelegate.window = window
        legacyAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        legacyAppDelegate.applicationDidBecomeActive(application)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        legacyAppDelegate.applicationWillResignActive(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        legacyAppDelegate.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        legacyAppDelegate.applicationWillEnterForeground(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        legacyAppDelegate.applicationWillTerminate(application)
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        legacyAppDelegate.applicationDidReceiveMemoryWarning(application)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        appCoordinator.open(url: url, options: options)
    }
    
    // MARK: User Activity Continuation
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        legacyAppDelegate.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    // MARK: Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        legacyAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        legacyAppDelegate.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        legacyAppDelegate.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}
