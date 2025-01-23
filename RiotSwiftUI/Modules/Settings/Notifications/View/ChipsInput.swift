//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Renders an input field and a collection of chips.
struct ChipsInput: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    @Environment(\.isEnabled) var isEnabled
    
    @State private var chipText = ""
    
    let titles: [String]
    let didAddChip: (String) -> Void
    let didDeleteChip: (String) -> Void
    var placeholder = ""
    
    var body: some View {
        VStack(spacing: 16) {
            TextField(placeholder, text: $chipText, onCommit: {
                didAddChip(chipText)
                chipText = ""
            })
            .disabled(!isEnabled)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .textFieldStyle(FormInputFieldStyle())
            Chips(titles: titles, didDeleteChip: didDeleteChip)
                .padding(.horizontal)
        }
    }
}

struct ChipsInput_Previews: PreviewProvider {
    static var chips = Set<String>(["Website", "Element", "Design", "Matrix/Element"])
    static var previews: some View {
        ChipsInput(titles: Array(chips)) { chip in
            chips.insert(chip)
        } didDeleteChip: { chip in
            chips.remove(chip)
        }
        .disabled(true)
    }
}
