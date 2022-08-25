/*
 Copyright 2019 New Vector Ltd
 
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

import Foundation
import Reusable

final class PasswordStrengthView: UIView, NibOwnerLoadable {
    // MARK: - Constants
    
    private enum StrengthColors {
        static let gray = UIColor(rgb: 0x9E9E9E)
        static let red = UIColor(rgb: 0xF56679)
        static let orange = UIColor(rgb: 0xFFC666)
        static let yellow = UIColor(rgb: 0xF8E71C)
        static let green = UIColor(rgb: 0x7AC9A1)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var firstStrengthView: UIView!
    @IBOutlet private var secondStrengthView: UIView!
    @IBOutlet private var thirdStrengthView: UIView!
    @IBOutlet private var fourthStrengthView: UIView!
    
    // MARK: Private
    
    private var strengthViews: [UIView] = []
    
    // MARK: Public
    
    var strength: PasswordStrength = .tooGuessable {
        didSet {
            self.updateStrengthColors()
        }
    }
    
    // MARK: - Setup
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        strengthViews = [firstStrengthView,
                         secondStrengthView,
                         thirdStrengthView,
                         fourthStrengthView]
        
        for strenghView in strengthViews {
            strenghView.layer.masksToBounds = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for strenghView in strengthViews {
            strenghView.layer.cornerRadius = strenghView.bounds.height / 2
        }
    }
    
    // MARK: - Private
    
    private func updateStrengthColors() {
        let strengthViewIndex: Int
        let color: UIColor
        
        switch strength {
        case .tooGuessable, .veryGuessable:
            strengthViewIndex = 0
            color = StrengthColors.red
        case .somewhatGuessable:
            strengthViewIndex = 1
            color = StrengthColors.orange
        case .safelyUnguessable:
            strengthViewIndex = 2
            color = StrengthColors.yellow
        case .veryUnguessable:
            strengthViewIndex = 3
            color = StrengthColors.green
        }
        
        self.color(until: strengthViewIndex, with: color)
    }
    
    private func color(until strengthViewIndex: Int, with color: UIColor) {
        var index = 0
        
        for strenghView in strengthViews {
            let strenghViewBackgroundColor: UIColor
            
            if index <= strengthViewIndex {
                strenghViewBackgroundColor = color
            } else {
                strenghViewBackgroundColor = StrengthColors.gray
            }
            
            strenghView.backgroundColor = strenghViewBackgroundColor
            
            index += 1
        }
    }
}
