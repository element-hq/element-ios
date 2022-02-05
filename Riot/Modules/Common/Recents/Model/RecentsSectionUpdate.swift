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

/// Object to represent a recents section update. Will be used as the `changes` parameter of `-[MXKDataSourceDelegate dataSource:didCellChange:]`method.
@objcMembers
class RecentsSectionUpdate: NSObject {

    /// Updated section index.
    let sectionIndex: Int

    /// Flag indicating the total counts on the section have changed or not.
    let totalCountsChanged: Bool

    init(withSectionIndex sectionIndex: Int,
         totalCountsChanged: Bool) {
        self.sectionIndex = sectionIndex
        self.totalCountsChanged = totalCountsChanged
        super.init()
    }

    /// Flag indicating the section update info is valid. If `true`, only the related section at `sectionIndex` can be reloaded.
    var isValid: Bool {
        return sectionIndex >= 0
    }
}
