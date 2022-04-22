// 
// Copyright 2020 Vector Creations Ltd
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

public extension Bundle {
    /// Returns the real app bundle.
    /// Can also be used in app extensions.
    @objc static let app: Bundle = {
        let bundle = main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                return otherBundle
            }
        }
        return bundle
    }()
    
    /// Get an lproj language bundle from the main app bundle.
    /// - Parameter language: The language to try to load.
    /// - Returns: The lproj bundle if found otherwise `nil`.
    @objc static func lprojBundle(for language: String) -> Bundle? {
        guard let lprojURL = Bundle.app.url(forResource: language, withExtension: "lproj") else { return nil }
        return Bundle(url: lprojURL)
    }
    
    /// Whether or not the bundle is the RiotShareExtension.
    var isShareExtension: Bool {
        bundleURL.lastPathComponent.contains("RiotShareExtension.appex")
    }
}
