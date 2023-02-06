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

struct SegmentedPicker<Segment: Hashable & CustomStringConvertible>: View {
    private let segments: [Segment]
    private let selection: Binding<Segment>
    private let interSegmentSpacing: CGFloat
    
    @Environment(\.theme) private var theme
    
    init(segments: [Segment], selection: Binding<Segment>, interSegmentSpacing: CGFloat) {
        self.segments = segments
        self.selection = selection
        self.interSegmentSpacing = interSegmentSpacing
    }
    
    var body: some View {
        HStack(spacing: interSegmentSpacing) {
            ForEach(segments, id: \.hashValue) { segment in
                let isSelectedSegment = segment == selection.wrappedValue
                
                Button {
                    selection.wrappedValue = segment
                } label: {
                    Text(segment.description)
                        .font(isSelectedSegment ? theme.fonts.headline : theme.fonts.body)
                        .underlineBar(isSelectedSegment)
                }
                .accentColor(isSelectedSegment ? theme.colors.accent : theme.colors.primaryContent)
                .accessibilityLabel(segment.description)
                .accessibilityValue(isSelectedSegment ? VectorL10n.accessibilitySelected : "")
            }
        }
    }
}

private extension Text {
    @ViewBuilder
    func underlineBar(_ isActive: Bool) -> some View {
        if #available(iOS 15.0, *) {
            overlay(alignment: .bottom) {
                if isActive {
                    Rectangle()
                        .frame(height: 1)
                        .offset(y: 2)
                }
            }
        } else {
            underline(isActive)
        }
    }
}

struct SegmentedPicker_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedPicker(
            segments: [
                "Segment 1",
                "Segment 2"
            ],
            selection: .constant("Segment 1"),
            interSegmentSpacing: 14
        )
        
        SegmentedPicker(
            segments: [
                "Segment 1",
                "Segment 2"
            ],
            selection: .constant("Segment 2"),
            interSegmentSpacing: 14
        )
    }
}
