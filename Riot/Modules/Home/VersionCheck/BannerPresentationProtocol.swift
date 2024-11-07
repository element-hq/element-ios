// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@objc protocol BannerPresentationProtocol {
    func presentBannerView(_ bannerView: UIView, animated: Bool)
    func dismissBannerView(animated: Bool)
}
