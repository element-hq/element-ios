// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import StoreKit
import UIKit

/// Presents the App Store page of the app replacing this one, so the user can download it.
enum ReplacementAppStorePresenter {
    /// Presents the App Store page of the app with the given App Store ID as a sheet.
    /// Falls back to opening the App Store URL outside of the app if the in-app page can't be shown.
    ///
    /// - Parameters:
    ///   - appStoreID: The App Store ID (a.k.a. iTunes item identifier) of the app.
    ///   - presenter: The view controller used to present the sheet.
    @MainActor static func presentStorePage(appStoreID: String, from presenter: UIViewController) async {
        do {
            let storeViewController = SKStoreProductViewController()
            try await storeViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appStoreID])
            presenter.present(storeViewController, animated: true)
        } catch {
            // Open the app store URL outside of the app as a fallback.
            MXLog.warning("[ReplacementAppStorePresenter] Unable to open the in-app store product page: \(error)")
            guard let appStoreURL = appStoreURL(for: appStoreID) else {
                MXLog.error("[ReplacementAppStorePresenter] Invalid App Store ID.")
                return
            }
            await UIApplication.shared.open(appStoreURL)
        }
    }
    
    /// The App Store URL of the app with the given App Store ID.
    static func appStoreURL(for appStoreID: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }
}
