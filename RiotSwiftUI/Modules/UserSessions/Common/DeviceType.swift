//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Client type
enum DeviceType {
    case desktop
    case web
    case mobile
    case unknown
    
    var image: Image {
        switch self {
        case .desktop:
            return Image(Asset.Images.deviceTypeDesktop.name)
        case .web:
            return Image(Asset.Images.deviceTypeWeb.name)
        case .mobile:
            return Image(Asset.Images.deviceTypeMobile.name)
        case .unknown:
            return Image(Asset.Images.deviceTypeUnknown.name)
        }
    }
    
    var name: String {
        switch self {
        case .desktop:
            return VectorL10n.deviceTypeNameDesktop
        case .web:
            return VectorL10n.deviceTypeNameWeb
        case .mobile:
            return VectorL10n.deviceTypeNameMobile
        case .unknown:
            return VectorL10n.deviceTypeNameUnknown
        }
    }
}
