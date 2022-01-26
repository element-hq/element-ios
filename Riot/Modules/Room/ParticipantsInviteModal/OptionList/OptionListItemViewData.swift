// 
// Copyright 2021 New Vector Ltd
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
