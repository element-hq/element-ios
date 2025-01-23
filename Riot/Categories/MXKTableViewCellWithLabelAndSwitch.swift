// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

extension MXKTableViewCellWithLabelAndSwitch: Reusable {}

extension MXKTableViewCellWithLabelAndSwitch: Themable {

    func update(theme: Theme) {
        mxkLabel.textColor = theme.textPrimaryColor
        backgroundColor = theme.backgroundColor
        contentView.backgroundColor = .clear
        mxkSwitch.onTintColor = theme.tintColor
   }

}
