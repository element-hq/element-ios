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

class InsettedTextField: UITextField {
    
    var insets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    var placeholderColor: UIColor? {
        didSet {
            updateAttributedPlaceholder()
        }
    }
    
    override var placeholder: String? {
        didSet {
            updateAttributedPlaceholder()
        }
    }
    
    private func updateAttributedPlaceholder() {
        guard let placeholder = placeholder else { return }
        guard let color = placeholderColor else { return }
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            NSAttributedString.Key.foregroundColor: color
        ])
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: insets)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: insets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: insets)
    }
    
}
