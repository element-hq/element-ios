//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Renders multiple chips in a flow layout.
struct Chips: View {
    @State private var frame = CGRect.zero
    
    let titles: [String]
    let didDeleteChip: (String) -> Void
    let verticalSpacing: CGFloat = 16
    let horizontalSpacing: CGFloat = 12
    
    var body: some View {
        Group {
            VStack {
                var x = CGFloat.zero
                var y = CGFloat.zero
                GeometryReader { geo in
                    ZStack(alignment: .topLeading, content: {
                        ForEach(titles, id: \.self) { chip in
                            Chip(title: chip) {
                                didDeleteChip(chip)
                            }
                            .alignmentGuide(.leading) { dimension in
                                // Align with leading side and move vertically down to next line
                                // if chip does not fit on trailing side.
                                if abs(x - dimension.width) > geo.size.width {
                                    x = 0
                                    y -= dimension.height + verticalSpacing
                                }
                                
                                let result = x
                                
                                if chip == titles.last {
                                    // Reset x if it's the last.
                                    x = 0
                                } else {
                                    // Align next chip to the end of the current one.
                                    x -= dimension.width + horizontalSpacing
                                }
                                return result
                            }
                            .alignmentGuide(.top) { _ in
                                // Use next y value and reset if its the last.
                                let result = y
                                if chip == titles.last {
                                    y = 0
                                }
                                return result
                            }
                        }
                    })
                    .background(ViewFrameReader(frame: $frame))
                }
            }
            .frame(height: frame.size.height)
        }
    }
}

struct Chips_Previews: PreviewProvider {
    static var chips: [String] = ["Chip1", "Chip2", "Chip3", "Chip4", "Chip5", "Chip6"]
    static var previews: some View {
        Group {
            Chips(titles: chips, didDeleteChip: { _ in })
            Chips(titles: chips, didDeleteChip: { _ in })
                .theme(.dark)
        }
    }
}
