//
// Copyright 2022 New Vector Ltd
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
import SwiftUI

struct LabelledDivider: View {
    @Environment(\.theme) private var theme

    let label: String
    let font: Font? // theme.fonts.subheadline by default
    let labelColor: Color? // theme.colors.primaryContent by default
    let lineColor: Color? // theme.colors.quinaryContent by default

    init(label: String,
         font: Font? = nil,
         labelColor: Color? = nil,
         lineColor: Color? = nil) {
        self.label = label
        self.font = font
        self.labelColor = labelColor
        self.lineColor = lineColor
    }

    var body: some View {
        HStack {
            line
            Text(label)
                .foregroundColor(labelColor ?? theme.colors.primaryContent)
                .font(font ?? theme.fonts.subheadline)
                .fixedSize()
            line
        }
    }

    var line: some View {
        VStack { Divider().background(lineColor ?? theme.colors.quinaryContent) }
    }
}

// MARK: - Previews

struct LabelledDivider_Previews: PreviewProvider {
    static var previews: some View {
        LabelledDivider(label: "Label")
            .theme(.light).preferredColorScheme(.light)
        LabelledDivider(label: "Label")
            .theme(.dark).preferredColorScheme(.dark)
    }
}
