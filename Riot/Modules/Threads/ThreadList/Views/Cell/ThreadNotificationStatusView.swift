// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
