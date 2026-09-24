// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// UIKit container of the `MigrationBanner` SwiftUI view, so it can be presented through `BannerPresentationProtocol`
/// and identified among the other banners.
final class MigrationBannerView: UIView {
    var contentView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let contentView = contentView {
                addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    topAnchor.constraint(equalTo: contentView.topAnchor),
                    bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
        }
    }
}
