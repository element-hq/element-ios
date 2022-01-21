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

import Foundation

class RoomMessageBubbleBackgroundView: UIView {
    
    // MARK: - Constant
    
    private enum Constants {
        static let cornerRadius: CGFloat = 12.0
    }
    
    // MARK: - Properties
    
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Setup
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    @discardableResult
    func updateHeight(_ height: CGFloat) -> Bool {
        if let heightConstraint = self.heightConstraint {
            
            guard heightConstraint.constant != height else {
                return false
            }
            
            heightConstraint.constant = height
            
            return true
        } else {
            let heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
            
            return true
        }
    }
}
