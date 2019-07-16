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

    init(apiUrl: NSString?, uiUrl: NSString?) {
        self.apiUrl = apiUrl
        self.uiUrl = uiUrl

        super.init()
    }

    override convenience init () {
        // Use app settings as default
        let apiUrl = UserDefaults.standard.object(forKey: "integrationsRestUrl") as? NSString
        let uiUrl = UserDefaults.standard.object(forKey: "integrationsUiUrl") as? NSString

        self.init(apiUrl: apiUrl, uiUrl: uiUrl)
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
