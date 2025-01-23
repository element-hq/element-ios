// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class CustomRoundedButton: UIButton {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 6.0
        static let fontSize: CGFloat = 17.0
    }
    
    // MARK: Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.layer.masksToBounds = true
        self.titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)        
        self.layer.cornerRadius = Constants.cornerRadius
    }
}
