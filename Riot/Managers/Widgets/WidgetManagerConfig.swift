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

/// Configuration for an integration manager.
/// By default, it uses URLs defined in the app settings but they can be overidden.
@objcMembers
class WidgetManagerConfig: NSObject, NSCoding {

    /// The URL for the REST api
    let apiUrl: NSString?
    /// The URL of the integration manager interface
    let uiUrl: NSString?
    /// The token if the user has been authenticated
    var scalarToken: NSString?

    var hasUrls: Bool {
        if apiUrl != nil && uiUrl != nil {
            return true
        } else {
            return false
        }
    }

    var baseUrl: NSString? {
        // Same comment as https://github.com/matrix-org/matrix-react-sdk/blob/1b0d8510a2ee93beddcd34c2d5770aa9fc76b1d9/src/ScalarAuthClient.js#L108
        // The terms endpoints are new and so live on standard _matrix prefixes,
        // but IM rest urls are currently configured with paths, so remove the
        // path from the base URL before passing it to the js-sdk

        // We continue to use the full URL for the calls done by
        // Riot-iOS, but the standard terms API called
        // by the matrix-ios-sdk lives on the standard _matrix path. This means we
        // don't support running IMs on a non-root path, but it's the only
        // realistic way of transitioning to _matrix paths since configs in
        // the wild contain bits of the API path.

        // Once we've fully transitioned to _matrix URLs, we can give people
        // a grace period to update their configs, then use the rest url as
        // a regular base url.
        guard let apiUrl = self.apiUrl as String?, let imApiUrl = URL(string: apiUrl) else {
            return nil
        }

        guard var baseUrl = URL(string: "/", relativeTo: imApiUrl)?.absoluteString else {
            return nil
        }

        if baseUrl.hasSuffix("/") {
            // SDK doest not like trailing /
            baseUrl = String(baseUrl.dropLast())
        }

        return baseUrl as NSString
    }

    init(apiUrl: NSString?, uiUrl: NSString?) {
        self.apiUrl = apiUrl
        self.uiUrl = uiUrl

        super.init()
    }

    /// MARK: - NSCoding

    enum CodingKeys: String {
        case apiUrl = "apiUrl"
        case uiUrl = "uiUrl"
        case scalarToken = "scalarToken"
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.apiUrl, forKey: CodingKeys.apiUrl.rawValue)
        aCoder.encode(self.uiUrl, forKey: CodingKeys.uiUrl.rawValue)
        aCoder.encode(self.scalarToken, forKey: CodingKeys.scalarToken.rawValue)
    }

    convenience required init?(coder aDecoder: NSCoder) {
        let apiUrl = aDecoder.decodeObject(forKey: CodingKeys.apiUrl.rawValue) as? NSString
        let uiUrl = aDecoder.decodeObject(forKey: CodingKeys.uiUrl.rawValue) as? NSString
        let scalarToken = aDecoder.decodeObject(forKey: CodingKeys.scalarToken.rawValue) as? NSString

        self.init(apiUrl: apiUrl, uiUrl: uiUrl)
        self.scalarToken = scalarToken
    }
}
