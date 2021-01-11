// 
// Copyright 2020 New Vector Ltd
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
