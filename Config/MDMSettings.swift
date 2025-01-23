// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum MDMSettings {
    private static let appleManagedConfigurationKey = "com.apple.configuration.managed"
    
    private enum Key: String {
        case serverConfigDefaultHomeserverUrlString = "im.vector.app.serverConfigDefaultHomeserverUrlString"
        case serverConfigSygnalAPIUrlString = "im.vector.app.serverConfigSygnalAPIUrlString"
        case clientPermalinkBaseUrl = "im.vector.app.clientPermalinkBaseUrl"
    }
    
    static var serverConfigDefaultHomeserverUrlString: String? {
        valueForKey(.serverConfigDefaultHomeserverUrlString) as? String
    }
    
    static var serverConfigSygnalAPIUrlString: String? {
        valueForKey(.serverConfigSygnalAPIUrlString) as? String
    }
    
    static var clientPermalinkBaseUrl: String? {
        valueForKey(.clientPermalinkBaseUrl) as? String
    }
    
    // MARK: - Private
    
    static private func valueForKey(_ key: Key) -> Any? {
        guard let managedConfiguration = UserDefaults.standard.dictionary(forKey: appleManagedConfigurationKey) else {
            print("MDM configuration missing")
            return nil
        }
        
        print("Retrieved MDM configuration: \(managedConfiguration)")
        
        return managedConfiguration[key.rawValue]
    }
}
