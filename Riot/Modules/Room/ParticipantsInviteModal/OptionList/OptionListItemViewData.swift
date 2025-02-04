// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class OptionListItemViewData {
    let title: String?
    let detail: String?
    let image: UIImage?
    let accessoryImage: UIImage?
    let enabled: Bool
    
    init(title: String? = nil,
         detail: String? = nil,
         image: UIImage? = nil,
         accessoryImage: UIImage? = Asset.Images.chevron.image,
         enabled: Bool = true) {
        self.title = title
        self.detail = detail
        self.image = image
        self.accessoryImage = accessoryImage
        self.enabled = enabled
    }
}
