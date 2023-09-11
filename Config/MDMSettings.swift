// 
// Copyright 2023 New Vector Ltd
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
