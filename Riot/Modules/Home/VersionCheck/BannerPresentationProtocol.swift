// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc protocol BannerPresentationProtocol {
    /// Present the given banner view.
    /// - Returns: `true` if the banner is displayed, `false` if it has been rejected because another banner with a higher priority is displayed.
    @discardableResult
    func presentBannerView(_ bannerView: UIView, animated: Bool) -> Bool
    
    /// Dismiss the currently displayed banner view, whatever it is.
    func dismissBannerView(animated: Bool)
    
    /// Dismiss the given banner view, only if it is the one currently displayed.
    func dismissBannerView(_ bannerView: UIView, animated: Bool)
}

extension Notification.Name {
    /// Posted by a `BannerPresentationProtocol` implementation once its banner slot becomes free,
    /// so that a banner previously rejected because of its lower priority can be presented.
    static let bannerPresenterDidFreeBannerSlot = Notification.Name("BannerPresenterDidFreeBannerSlot")
}
