// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct DestructiveButton<Label>: View where Label : View {
    var action: () -> Void
    var label: () -> Label

    var body: some View {
        if #available(iOS 15, *) {
            return Button(role: .destructive, action: action, label: label)
        } else {
            return Button(action: action, label: label)
        }
    }
}
