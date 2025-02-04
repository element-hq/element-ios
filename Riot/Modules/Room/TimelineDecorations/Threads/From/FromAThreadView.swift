// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
