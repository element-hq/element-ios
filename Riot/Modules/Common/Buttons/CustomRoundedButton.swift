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

class CustomRoundedButton: UIButton {
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 6.0
        static let fontSize: CGFloat = 17.0
    }
    
    // MARK: Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.masksToBounds = true
        titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)
        layer.cornerRadius = Constants.cornerRadius
    }
}
