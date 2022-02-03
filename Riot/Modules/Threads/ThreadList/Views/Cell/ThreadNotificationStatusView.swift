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

/// Dot view for a thread notification status
class ThreadNotificationStatusView: UIView {
    
    private var theme: Theme

    init(withTheme theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        theme = ThemeService.shared().theme
        super.init(coder: coder)
    }
    
    /// Current status. Update this property to change background color accordingly.
    var status: ThreadNotificationStatus = .none {
        didSet {
            updateBgColor()
        }
    }
    
    private func updateBgColor() {
        switch status {
        case .none:
            backgroundColor = .clear
        case .notified:
            backgroundColor = theme.colors.secondaryContent
        case .highlighted:
            backgroundColor = theme.colors.alert
        }
    }
    
}

extension ThreadNotificationStatusView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        updateBgColor()
    }
    
}
