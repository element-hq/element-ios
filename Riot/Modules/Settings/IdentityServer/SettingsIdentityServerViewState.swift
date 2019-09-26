// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
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

/// SettingsIdentityServerViewController view state
enum SettingsIdentityServerViewState {
    case loading
    case loaded(displayMode: SettingsIdentityServerDisplayMode)
    case presentTerms(session: MXSession, accessToken: String, baseUrl: String, onComplete: (Bool) -> Void)
    case alert(alert: SettingsIdentityServerAlert, onContinue: () -> Void)
    case error(Error)
}

enum SettingsIdentityServerDisplayMode {
    case noIdentityServer
    case identityServer(host: String)
}

/// Alerts that can be presented when the user triggered an action among SettingsIdentityServerViewAction.
/// These alerts allow interaction with the user to complete the action flow.
enum SettingsIdentityServerAlert {
    case addActionAlert(AddActionAlert)
    case changeActionAlert(ChangeActionAlert)
    case disconnectActionAlert(DisconnectActionAlert)

    enum AddActionAlert {
        case invalidIdentityServer(newHost: String)
        case noTerms(newHost: String)
        case termsNotAccepted(newHost: String)
    }

    enum ChangeActionAlert {
        case invalidIdentityServer(newHost: String)
        case noTerms(newHost: String)
        case termsNotAccepted(newHost: String)
        case stillSharing3Pids(oldHost: String, newHost: String)
        case doubleConfirmation(oldHost: String, newHost: String)
    }

    enum DisconnectActionAlert {
        case stillSharing3Pids(oldHost: String)
        case doubleConfirmation(oldHost: String)
    }
}
