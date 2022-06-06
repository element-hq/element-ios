// 
// Copyright 2022 New Vector Ltd
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

/// Set of methods to be able to login to an existing account on a homeserver.
///
/// More documentation can be found in the file https://github.com/vector-im/element-android/blob/main/docs/signin.md
class LoginWizard {
    struct State {
        /// For SSO session recovery
        var deviceId: String?
        var resetPasswordEmail: String?
        var resetPasswordData: ResetPasswordData?
        
        var clientSecret = UUID().uuidString
        var sendAttempt: UInt = 0
    }
    
    let client: AuthenticationRestClient
    let sessionCreator: SessionCreatorProtocol
    
    private(set) var state: State
    
    init(client: AuthenticationRestClient, sessionCreator: SessionCreatorProtocol) {
        self.client = client
        self.sessionCreator = sessionCreator
        
        self.state = State()
    }
    
//    /// Get some information about a matrixId: displayName and avatar url
//    func profileInfo(for matrixID: String) async -> LoginProfileInfo {
//
//    }
    
    /// Login to the homeserver.
    /// - Parameters:
    ///   - login: The login field. Can be a user name, or a msisdn (email or phone number) associated to the account.
    ///   - password: The password of the account.
    ///   - initialDeviceName: The initial device name.
    ///   - deviceID: The device ID, optional. If not provided or nil, the server will generate one.
    /// - Returns: An `MXSession` if the login is successful.
    func login(login: String, password: String, initialDeviceName: String, deviceID: String? = nil) async throws -> MXSession {
        let parameters: LoginPasswordParameters
        
        if MXTools.isEmailAddress(login) {
            parameters = LoginPasswordParameters(id: .thirdParty(medium: .email, address: login),
                                                 password: password,
                                                 deviceDisplayName: initialDeviceName,
                                                 deviceID: deviceID)
        } else {
            parameters = LoginPasswordParameters(id: .user(login),
                                                 password: password,
                                                 deviceDisplayName: initialDeviceName,
                                                 deviceID: deviceID)
        }
        
        let credentials = try await client.login(parameters: parameters)
        return sessionCreator.createSession(credentials: credentials, client: client)
    }
    
    /// Exchange a login token to an access token.
    /// - Parameter loginToken: A login token, obtained when login has happened in a WebView, using SSO.
    /// - Returns: An `MXSession` if the login is successful.
    func login(with token: String) async throws -> MXSession {
        let parameters = LoginTokenParameters(token: token)
        let credentials = try await client.login(parameters: parameters)
        return sessionCreator.createSession(credentials: credentials, client: client)
    }
    
//    /// Login to the homeserver by sending a custom JsonDict.
//    /// The data should contain at least one entry `type` with a String value.
//    func loginCustom(data: Codable) async -> MXSession {
//
//    }

    /// Ask the homeserver to reset the user password. The password will not be
    /// reset until `resetPasswordMailConfirmed` is successfully called.
    /// - Parameters:
    ///   - email: An email previously associated to the account the user wants the password to be reset.
    func resetPassword(email: String) async throws {
        let result = try await client.forgetPassword(for: email,
                                                     clientSecret: state.clientSecret,
                                                     sendAttempt: state.sendAttempt)

        state.sendAttempt += 1
        state.resetPasswordData = ResetPasswordData(addThreePIDSessionID: result)
    }

    /// Confirm the new password, once the user has checked their email.
    /// When this method succeeds, the account password will be effectively modified.
    /// - Parameters:
    ///   - newPassword: The desired new password
    ///   - signoutAllDevices: The flag to sign out of all devices
    func resetPasswordMailConfirmed(newPassword: String, signoutAllDevices: Bool) async throws {
        guard let resetPasswordData = state.resetPasswordData else {
            MXLog.error("[LoginWizard] resetPasswordMailConfirmed: Reset password data missing. Call resetPassword first.")
            throw LoginError.resetPasswordNotStarted
        }
        
        let parameters = CheckResetPasswordParameters(clientSecret: state.clientSecret,
                                                      sessionID: resetPasswordData.addThreePIDSessionID,
                                                      newPassword: newPassword,
                                                      signoutAllDevices: signoutAllDevices)
        
        try await client.resetPassword(parameters: parameters)
        
        state.resetPasswordData = nil
    }
}
