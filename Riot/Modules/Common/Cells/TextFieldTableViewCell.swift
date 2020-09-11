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
import Reusable

/// Table view cell with only a text field spanning the whole content view, insets can be configured via `textField.insets`
class TextFieldTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: InsettedTextField!
    
}

extension TextFieldTableViewCell: NibReusable {}

extension TextFieldTableViewCell: Themable {
    
    func update(theme: Theme) {
        theme.applyStyle(onTextField: textField)
        textField.placeholderColor = theme.placeholderTextColor
    }
    
}
