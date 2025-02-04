// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK
import GBDeviceInfo

extension MXBugReportRestClient {
    
    @objc static func vc_bugReportRestClient(appName: String) -> MXBugReportRestClient {
        let client = MXBugReportRestClient(bugReportEndpoint: BuildSettings.bugReportEndpointUrlString)
        // App info
        client.appName = appName
        client.version = AppDelegate.theDelegate().appVersion
        client.build = AppDelegate.theDelegate().build
        
        client.deviceModel = GBDeviceInfo.deviceInfo().modelString
        client.deviceOS = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        return client
    }
    
    @objc func vc_sendBugReport(
        description: String,
        sendLogs: Bool,
        sendCrashLog: Bool,
        sendFiles: [URL]? = nil,
        additionalLabels: [String]? = nil,
        customFields: [String: String]? = nil,
        progress: ((MXBugReportState, Progress?) -> Void)? = nil,
        success: ((String?) -> Void)? = nil,
        failure: ((Error?) -> Void)? = nil
    ) {
        // User info (TODO: handle multi-account and find a way to expose them in rageshake API)
        var userInfo = [String: String]()
        let mainAccount = MXKAccountManager.shared().accounts.first
        if let userId = mainAccount?.mxSession?.myUser?.userId {
            userInfo["user_id"] = userId
        }
        if let deviceId = mainAccount?.mxSession?.myDeviceId {
            userInfo["device_id"] = deviceId
        }
        
        userInfo["locale"] = NSLocale.preferredLanguages[0]
        userInfo["default_app_language"] = Bundle.main.preferredLocalizations[0] // The language chosen by the OS
        userInfo["app_language"] = Bundle.mxk_language() ?? userInfo["default_app_language"] // The language chosen by the user
        
        // Application settings
        userInfo["lazy_loading"] = MXKAppSettings.standard().syncWithLazyLoadOfRoomMembers ? "ON" : "OFF"
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        userInfo["local_time"] = dateFormatter.string(from: currentDate)
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        userInfo["utc_time"] = dateFormatter.string(from: currentDate)
        
        // SDKs
        userInfo["matrix_sdk_version"] = MatrixSDKVersion
        if let crypto = mainAccount?.mxSession?.crypto {
            userInfo["crypto_module_version"] = crypto.version
        }
        
        if let customFields = customFields {
            // combine userInfo with custom fields overriding with custom where there is a conflict
            userInfo.merge(customFields) { (_, new) in new }
        }
        others = userInfo
        
        var labels: [String] = additionalLabels ?? [String]()
        // Add a Github label giving information about the version
        if var versionLabel = version, let buildLabel = build {
            
            // If this is not the app store version, be more accurate on the build origin
            if buildLabel == VectorL10n.settingsConfigNoBuildInfo {
                // This is a debug session from Xcode
                versionLabel += "-debug"
            } else if !buildLabel.contains("master") {
                // This is a Jenkins build. Add the branch and the build number
                let buildString = buildLabel.replacingOccurrences(of: " ", with: "-")
                versionLabel += "-\(buildString)"
            }
            labels += [versionLabel]
        }
        if sendCrashLog {
            labels += ["crash"]
        }
        
        var sendDescription = description
        if sendCrashLog,
           let crashLogFile = MXLogger.crashLog(),
           let crashLog = try? String(contentsOfFile: crashLogFile, encoding: .utf8) {
            // Append the crash dump to the user description in order to ease triaging of GH issues
            sendDescription += "\n\n\n--------------------------------------------------------------------------------\n\n\(crashLog)"
        }
        
        sendBugReport(sendDescription,
            sendLogs: sendLogs,
            sendCrashLog: sendCrashLog,
            sendFiles: sendFiles,
            attachGitHubLabels: labels,
            progress: progress,
            success: success,
            failure: failure)
    }
    
}
