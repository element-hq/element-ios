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

/// SettingsDiscoveryTableViewSection view state
enum SettingsDiscoveryViewState {
    case loading
    case loaded(displayMode: SettingsDiscoveryDisplayMode)
    case error(Error)
}

enum SettingsDiscoveryDisplayMode {
    case noIdentityServer
    case termsNotSigned(host: String)
    case noThreePidsAdded
    case threePidsAdded(emails: [MX3PID], phoneNumbers: [MX3PID])
}
