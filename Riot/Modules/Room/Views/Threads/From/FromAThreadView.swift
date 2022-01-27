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
import Reusable

@objcMembers
class FromAThreadView: UIView {

    private enum Constants {
        static let viewHeight: CGFloat = 18
    }

    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    static func contentViewHeight(forEvent event: MXEvent,
                                  fitting maxWidth: CGFloat) -> CGFloat {
        return Constants.viewHeight
    }

    static func instantiate() -> FromAThreadView {
        let view = FromAThreadView.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        view.titleLabel.text = VectorL10n.messageFromAThread
        return view
    }

}

extension FromAThreadView: NibLoadable {}

extension FromAThreadView: Themable {

    func update(theme: Theme) {
        backgroundColor = .clear
        iconView.tintColor = theme.colors.secondaryContent
        titleLabel.textColor = theme.colors.secondaryContent
    }

}
