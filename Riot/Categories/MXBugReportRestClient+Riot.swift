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
        if let userId = mainAccount?.mxSession.myUser.userId {
            userInfo["user_id"] = userId
        }
        if let deviceId = mainAccount?.mxSession.matrixRestClient.credentials.deviceId {
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
