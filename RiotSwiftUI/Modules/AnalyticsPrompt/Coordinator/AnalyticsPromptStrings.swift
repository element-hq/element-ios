//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct AnalyticsPromptStrings: AnalyticsPromptStringsProtocol {
    let point1 = HTMLFormatter.formatHTML(VectorL10n.analyticsPromptPoint1,
                                          withAllowedTags: ["b", "p"],
                                          font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    let point2 = HTMLFormatter.formatHTML(VectorL10n.analyticsPromptPoint2,
                                          withAllowedTags: ["b", "p"],
                                          font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
}
