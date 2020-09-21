// 
// Copyright 2020 New Vector Ltd
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

/// This can be used in grouped table views to hide section separators for a specific cell.
class GroupedTableViewCell: UITableViewCell {
    
    /// Set to true in order to hide section separators. Default is `false`.
    var hideSectionSeparators: Bool = false {
        didSet {
            if hideSectionSeparators {
                removeSectionSeparators()
            }
        }
    }
    
    private func removeSectionSeparators() {
        for subview in subviews {
            if subview != contentView && subview.bounds.width == bounds.width {
                subview.removeFromSuperview()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if hideSectionSeparators {
            removeSectionSeparators()
        }
    }
    
}
