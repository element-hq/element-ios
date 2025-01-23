//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    func login(parameters: [String: Any]) async throws -> MXCredentials
    
    func generateLoginToken() async throws -> MXLoginToken
    
    // MARK: Registration

    var registerFallbackURL: URL { get }
    func getRegisterSession() async throws -> MXAuthenticationSession
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func register(parameters: RegistrationParameters) async throws -> MXLoginResponse
    func register(parameters: [String: Any]) async throws -> MXLoginResponse
    func requestTokenDuringRegistration(for threePID: RegisterThreePID, clientSecret: String, sendAttempt: UInt) async throws -> RegistrationThreePIDTokenResponse
    
    // MARK: Forgot Password

    func forgetPassword(for email: String, clientSecret: String, sendAttempt: UInt) async throws -> String
    func resetPassword(parameters: CheckResetPasswordParameters) async throws
    func resetPassword(parameters: [String: Any]) async throws

    // MARK: Versions

    func supportedMatrixVersions() async throws -> MXMatrixVersions
}

extension MXRestClient: AuthenticationRestClient { }
