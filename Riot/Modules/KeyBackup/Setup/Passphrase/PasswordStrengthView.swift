/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

    @IBOutlet private weak var firstStrengthView: UIView!
    @IBOutlet private weak var secondStrengthView: UIView!
    @IBOutlet private weak var thirdStrengthView: UIView!
    @IBOutlet private weak var fourthStrengthView: UIView!
    
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
        let color: UIColor
        
        switch self.strength {
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
        var index: Int = 0
        
        for strenghView in self.strengthViews {
            
            let strenghViewBackgroundColor: UIColor
            
            if index <= strengthViewIndex {
                strenghViewBackgroundColor = color
            } else {
                strenghViewBackgroundColor = StrengthColors.gray
            }
            
            strenghView.backgroundColor = strenghViewBackgroundColor
            
            index+=1
        }
    }
}
