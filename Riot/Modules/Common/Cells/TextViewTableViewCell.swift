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

/// Table view cell with only a text view spanning the whole content view, insets can be configured via `textView.textContainerInset`
class TextViewTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: PlaceholderedTextView!
    
}

extension TextViewTableViewCell: NibReusable {}

extension TextViewTableViewCell: Themable {
    
    func update(theme: Theme) {
        textView.textColor = theme.textPrimaryColor
        textView.tintColor = theme.tintColor
        textView.placeholderColor = theme.placeholderTextColor
    }
    
}
