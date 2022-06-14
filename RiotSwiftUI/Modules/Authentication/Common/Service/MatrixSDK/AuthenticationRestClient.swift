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

protocol AuthenticationRestClient: AnyObject {
    // MARK: Configuration
    var homeserver: String! { get }
    var identityServer: String! { get set }
    var credentials: MXCredentials! { get }
    var acceptableContentTypes: Set<String>! { get set }
    
    init(homeServer: URL, unrecognizedCertificateHandler handler: MXHTTPClientOnUnrecognizedCertificate?)
    
    // MARK: Login
    var loginFallbackURL: URL { get }
    func wellKnown() async throws -> MXWellKnown
    func getLoginSession() async throws -> MXAuthenticationSession
    func login(parameters: LoginParameters) async throws -> MXCredentials
    func login(parameters: [String : Any]) async throws -> MXCredentials
    
    // MARK: Registration
    var registerFallbackURL: URL { get }
    func getRegisterSession() async throws -> MXAuthenticationSession
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func register(parameters: RegistrationParameters) async throws -> MXLoginResponse
    func register(parameters: [String : Any]) async throws -> MXLoginResponse
    func requestTokenDuringRegistration(for threePID: RegisterThreePID, clientSecret: String, sendAttempt: UInt) async throws -> RegistrationThreePIDTokenResponse
    
    // MARK: Forgot Password
    func forgetPassword(for email: String, clientSecret: String, sendAttempt: UInt) async throws -> String
    func resetPassword(parameters: CheckResetPasswordParameters) async throws
    func resetPassword(parameters: [String : Any]) async throws
}

extension MXRestClient: AuthenticationRestClient { }
