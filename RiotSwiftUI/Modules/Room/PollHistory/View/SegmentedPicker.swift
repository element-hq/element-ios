// 
// Copyright 2023 New Vector Ltd
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

struct SegmentedPicker<Tag: Hashable>: View {
    private let segments: [(String, Tag)]
    private let selection: Binding<Tag>
    private let interSegmentSpacing: CGFloat
    
    @Environment(\.theme) private var theme
    
    init(segments: [(String, Tag)], selection: Binding<Tag>, interSegmentSpacing: CGFloat) {
        self.segments = segments
        self.selection = selection
        self.interSegmentSpacing = interSegmentSpacing
    }
    
    var body: some View {
        HStack(spacing: interSegmentSpacing) {
            ForEach(segments, id: \.1) { text, tag in
                let isSelectedSegment = tag == selection.wrappedValue
                
                Button {
                    selection.wrappedValue = tag
                } label: {
                    Text(text)
                        .font(isSelectedSegment ? theme.fonts.headline : theme.fonts.body)
                        .underline(isSelectedSegment)
                }
                .accentColor(isSelectedSegment ? theme.colors.accent : theme.colors.primaryContent)
            }
        }
    }
}

struct SegmentedPicker_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedPicker(
            segments: [
                ("Segment 1", "1"),
                ("Segment 2", "2")
            ],
            selection: .constant("1"),
            interSegmentSpacing: 14
        )
    }
}
