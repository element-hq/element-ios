// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a homeserver configuration used for the mock authentication client.
extension MockAuthenticationRestClient {
    enum Config: String {
        /// A homeserver that mimics matrix.org with both passwords and SSO.
        /// Create the client using https://matrix.org for this configuration.
        case matrix
        
        /// A homeserver that supports login and registration using a password.
        /// Create the client using https://example.com for this configuration.
        case basic
        
        /// A homeserver that only supports login using a password and has registration disabled.
        /// This configuration doesn't returns a well-known response.
        /// Create the client using https://private.com for this configuration.
        case loginOnly
        
        /// A homeserver the only supports login via SSO and has registration disabled.
        /// This configuration has a custom identity server configured.
        /// Create the client using https://company.com for this configuration.
        case ssoOnly
        
        /// The client if configured to use an unknown address.
        /// Create the client using any other address for this configuration.
        case unknown
        
        init(url: URL) {
            switch url.absoluteString {
            case "https://matrix.org", "https://matrix-client.matrix.org":
                self = .matrix
            case "https://example.com", "https://matrix.example.com":
                self = .basic
            case "https://private.com":
                self = .loginOnly
            case "https://company.com", "https://matrix.company.com":
                self = .ssoOnly
            default:
                self = .unknown
            }
        }
        
        /// The baseURL for the homeserver.
        var baseURL: String {
            switch self {
            case .matrix:
                return "matrix.org"
            case .basic:
                return "example.com"
            case .loginOnly:
                return "private.com"
            case .ssoOnly:
                return "company.com"
            case .unknown:
                return ""
            }
        }
        
        /// The supported stages when performing interactive registration.
        var supportedStages: Set<String>? {
            switch self {
            case .matrix:
                return [kMXLoginFlowTypeRecaptcha, kMXLoginFlowTypeTerms, kMXLoginFlowTypeEmailIdentity]
            case .basic:
                return [kMXLoginFlowTypeDummy]
            case .loginOnly, .ssoOnly, .unknown:
                return nil
            }
        }
        
        /// Returns the well-known JSON for this configuration
        func wellKnownJSON() throws -> [AnyHashable: Any] {
            try fixtureJSON(named: "wellknown")
        }
        
        /// Returns the login session JSON for this configuration
        func loginSessionJSON() throws -> [AnyHashable: Any] {
            try fixtureJSON(named: "loginsession")
        }
        
        /// Returns the register session JSON for this configuration
        func registerSessionJSON() throws -> [AnyHashable: Any] {
            switch self {
            case .matrix, .basic:
                return try fixtureJSON(named: "registersession")
            case .loginOnly, .ssoOnly:
                throw MockError.registrationDisabled
            case .unknown:
                throw  MockError.unhandled
            }
        }
        
        /// Loads a JSON fixture for this configuration.
        /// - Parameter fileName: The file name of the fixture without the configuration prefix.
        private func fixtureJSON(named fileName: String) throws -> [AnyHashable: Any] {
            let fileName = "\(rawValue)-\(fileName)"
            let data = try fixtureData(named: fileName)
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any] else { throw MockError.fixture }
            return jsonDictionary
        }
        
        /// Loads the raw data for a fixture from disk.
        /// - Parameter fileName: The file name of the fixture as stored in the bundle.
        private func fixtureData(named fileName: String) throws -> Data {
            let bundle = Bundle(for: MockAuthenticationRestClient.self)
            
            guard let url = bundle.url(forResource: fileName, withExtension: "json") else { throw MockError.fixture }
            return try Data(contentsOf: url)
        }
    }
}
