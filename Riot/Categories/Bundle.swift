// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
