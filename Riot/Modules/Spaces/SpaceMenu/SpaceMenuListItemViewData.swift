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

import Foundation

/// Style of the `SpaceMenuListViewCell`
enum SpaceMenuListItemStyle {
    case normal
    case boolean
    case destructive
}

/// `SpaceMenuListItemViewDataDelegate` allows the table view cell to update its view accordingly with it's related data change
protocol SpaceMenuListItemViewDataDelegate: AnyObject {
    func spaceMenuItemValueDidChange(_ item: SpaceMenuListItemViewData)
}

/// `SpaceMenuListViewCell` view data
class SpaceMenuListItemViewData {
    let actionId: String
    let style: SpaceMenuListItemStyle
    let title: String?
    let icon: UIImage?
    
    var value: Any? {
        didSet {
            delegate?.spaceMenuItemValueDidChange(self)
        }
    }
    weak var delegate: SpaceMenuListItemViewDataDelegate?
    
    init(actionId: String, style: SpaceMenuListItemStyle, title: String?, icon: UIImage?, value: Any?) {
        self.actionId = actionId
        self.style = style
        self.title = title
        self.icon = icon
        self.value = value
    }
}
