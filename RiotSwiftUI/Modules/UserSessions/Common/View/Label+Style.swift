// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension Label where Title == Text, Icon == Image  {
    init(showLocationInfo: Bool) {
        let text = showLocationInfo ? VectorL10n.userSessionsHideLocationInfo : VectorL10n.userSessionsShowLocationInfo
        let image = showLocationInfo ? "eye.slash" : "eye"
        self.init(text, systemImage: image)
    }
}
