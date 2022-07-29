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
import UIKit
import Reusable

class AllChatsActionPanelView: UIVisualEffectView, NibLoadable, Themable {
    
    // MARK: - Outlets
    
    @IBOutlet weak var spaceButton: UIButton!
    @IBOutlet weak var spaceButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var editButtonTrailingConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        setup(button: editButton)
        setup(button: spaceButton)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        editButton.tintColor = theme.colors.accent
        spaceButton.tintColor = theme.colors.accent
    }

    // MARK: - Private
    
    private func setup(button: UIButton) {
        button.setTitle("", for: .normal)
        button.tintColor = ThemeService.shared().theme.colors.accent
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 1.2
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
    }
}
