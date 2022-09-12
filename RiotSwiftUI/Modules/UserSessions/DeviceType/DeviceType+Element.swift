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

extension DeviceType {
    
    var image: Image {
        
        let image: Image
        
        switch self {
        case .desktop:
            image = Image(Asset.Images.deviceTypeDesktop.name)
        case .web:
            image = Image(Asset.Images.deviceTypeWeb.name)
        case .mobile:
            image = Image(Asset.Images.deviceTypeMobile.name)
        case .unknown:
            image = Image(Asset.Images.deviceTypeUnknown.name)
        }
        
        return image
    }
    
    var name: String {
        let name: String
        
        let appName = AppInfo.current.displayName
        
        switch self {
        case .desktop:
            name = VectorL10n.deviceNameDesktop(appName)
        case .web:
            name = VectorL10n.deviceNameWeb(appName)
        case .mobile:
            name = VectorL10n.deviceNameMobile(appName)
        case .unknown:
            name = VectorL10n.deviceNameUnknown
        }
        
        return name
    }
}
