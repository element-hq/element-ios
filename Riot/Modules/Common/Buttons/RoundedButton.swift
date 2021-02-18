/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

final class RoundedButton: CustomRoundedButton, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let backgroundColorAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var theme: Theme?
    
    // MARK: Public
    
    var actionStyle: UIAlertAction.Style = .default {
        didSet {
            self.updateButtonStyle()
        }
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Private
    
    private func updateButtonStyle() {
        guard let theme = theme else {
            return
        }
        
        let backgroundColor: UIColor
        
        switch self.actionStyle {
        case .default:
            backgroundColor = theme.tintColor
        default:
            backgroundColor = theme.noticeColor
        }
        
        self.vc_setBackgroundColor(backgroundColor.withAlphaComponent(Constants.backgroundColorAlpha), for: .normal)
        self.setTitleColor(backgroundColor, for: .normal)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.theme = theme
        self.updateButtonStyle()
    }
}
