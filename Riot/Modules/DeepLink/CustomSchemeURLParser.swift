// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum CustomSchemeURLParserError: Error {
    case unknownHost
    case invalidParameters
    case unknown
}

/// CustomSchemeURLParser enables to parse custom scheme URL
class CustomSchemeURLParser {
        
    func parse(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) throws -> DeepLinkOption {
        guard let host = url.host else {
            throw CustomSchemeURLParserError.unknownHost
        }
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw CustomSchemeURLParserError.unknown
        }
        
        let deepLinkOption: DeepLinkOption
        
        switch host {
        case CustomSchemeURLConstants.Hosts.connect:
            if let deepLinkOpt = self.buildDeepLinkConnect(from: urlComponents) {
                deepLinkOption = deepLinkOpt
            } else {
                throw CustomSchemeURLParserError.invalidParameters
            }
        default:
            throw CustomSchemeURLParserError.unknownHost
        }
        
        return deepLinkOption
    }
    
    private func buildDeepLinkConnect(from urlComponents: URLComponents) -> DeepLinkOption? {
        guard let queryItems = urlComponents.queryItems, queryItems.isEmpty == false else {
            return nil
        }
        
        guard let loginToken = urlComponents.vc_getQueryItemValue(for: SSOURLConstants.Parameters.callbackLoginToken)  else {
            return nil
        }
        
        guard let txnId = urlComponents.vc_getQueryItemValue(for: CustomSchemeURLConstants.Parameters.transactionId) else {
            return nil
        }
        
        return DeepLinkOption.connect(loginToken, txnId)
    }
}
