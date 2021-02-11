// 
// Copyright 2020 New Vector Ltd
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

/// Digit button class for Dialpad screen
class DialpadButton: UIButton {
    
    private enum Constants {
        static let size: CGSize = CGSize(width: 68, height: 68)
    }
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: Constants.size))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = Constants.size.width/2
    }
    
}

//  MARK: - Themable

extension DialpadButton: Themable {
    
    func update(theme: Theme) {
        setTitleColor(theme.textPrimaryColor, for: .normal)
        backgroundColor = theme.headerBackgroundColor
    }
    
}
