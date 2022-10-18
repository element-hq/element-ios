//
// Copyright 2022 New Vector Ltd
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
