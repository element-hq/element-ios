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

import Foundation
import Reusable

@objc protocol CallBarDelegate: class {
    func callBarDidTapReturnButton(_ callBar: CallBar)
}

@objcMembers
class CallBar: UIView, NibLoadable {
    
    @IBOutlet private weak var callIcon: UIImageView! {
        didSet {
            callIcon.image = Asset.Images.voiceCallHangonIcon.image.vc_tintedImage(usingColor: .white)
        }
    }
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var returnLabel: UILabel! {
        didSet {
            returnLabel.text = VectorL10n.callbarReturn
        }
    }
    @IBOutlet private weak var returnButton: UIButton!
    
    weak var delegate: CallBarDelegate?
    
    static func instantiate() -> CallBar {
        return CallBar.loadFromNib()
    }
    
    var title: String? {
        get {
            return titleLabel.text
        } set {
            titleLabel.text = newValue
        }
    }
    
    @IBAction private func returnButtonTapped(_ sender: UIButton) {
        delegate?.callBarDidTapReturnButton(self)
    }
}
