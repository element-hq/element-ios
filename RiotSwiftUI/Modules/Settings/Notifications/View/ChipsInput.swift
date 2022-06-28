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

import SwiftUI

/// Renders an input field and a collection of chips.
struct ChipsInput: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    @Environment(\.isEnabled) var isEnabled
    
    @State private var chipText: String = ""
    
    let titles: [String]
    let didAddChip: (String) -> Void
    let didDeleteChip: (String) -> Void
    var placeholder: String = ""
    
    
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
