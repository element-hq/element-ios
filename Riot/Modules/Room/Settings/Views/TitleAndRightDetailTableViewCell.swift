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

class TitleAndRightDetailTableViewCell: MXKTableViewCell {
    
    // MARK: Outlet
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    
    // MARK: Properties
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            titleLabel.alpha = isUserInteractionEnabled ? 1 : 0.3
            detailLabel.alpha = isUserInteractionEnabled ? 1 : 0.3
        }
    }

    // MARK: - MXKTableViewCell
    
    override func customizeRendering() {
        super.customizeRendering()
        
        let theme = ThemeService.shared().theme
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.body
        
        detailLabel.textColor = theme.colors.secondaryContent
        detailLabel.font = theme.fonts.body
    }
}
