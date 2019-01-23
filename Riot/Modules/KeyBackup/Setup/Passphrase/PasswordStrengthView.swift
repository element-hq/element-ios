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
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var firstStrengthView: UIView!
    @IBOutlet private weak var secondStrengthView: UIView!
    @IBOutlet private weak var thirdStrengthView: UIView!
    @IBOutlet private weak var fourthStrengthView: UIView!
    
    // MARK: Private
    
    private var strengthViews: [UIView] = []
    
    private let strengthViewDefaultColor = UIColor(rgb: 0x9E9E9E)
    
    private var strengthViewColors: [Int: UIColor] = [
        0: UIColor(rgb: 0xF56679),
        1: UIColor(rgb: 0xFFC666),
        2: UIColor(rgb: 0xF8E71C),
        3: UIColor(rgb: 0x7AC9A1)
    ]
    
    // MARK: Public
    
    var strength: PasswordStrength = .tooGuessable {
        didSet {
            self.updateStrengthColors()
        }
    }
    
    // MARK: - Setup
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.strengthViews = [self.firstStrengthView,
                              self.secondStrengthView,
                              self.thirdStrengthView,
                              self.fourthStrengthView]
        
        for strenghView in self.strengthViews {
            strenghView.layer.masksToBounds = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for strenghView in self.strengthViews {            
            strenghView.layer.cornerRadius = strenghView.bounds.height/2
        }
    }
    
    // MARK: - Private    
    
    private func updateStrengthColors() {
        let strengthViewIndex: Int
        
        switch self.strength {
        case .tooGuessable, .veryGuessable:
            strengthViewIndex = 0
        case .somewhatGuessable:
            strengthViewIndex = 1
        case .safelyUnguessable:
            strengthViewIndex = 2
        case .veryUnguessable:
            strengthViewIndex = 3
        }
        
        self.color(until: strengthViewIndex)
    }
    
    private func color(until strengthViewIndex: Int) {
        var index: Int = 0
        
        for strenghView in self.strengthViews {
            
            let color: UIColor
            
            if index <= strengthViewIndex {
                color = self.color(for: index)
            } else {
                color = self.strengthViewDefaultColor
            }
            
            strenghView.backgroundColor = color
            
            index+=1
        }
    }
    
    private func color(for index: Int) -> UIColor {
        guard let color = self.strengthViewColors[index] else {
            return self.strengthViewDefaultColor
        }
        return color
    }
}
