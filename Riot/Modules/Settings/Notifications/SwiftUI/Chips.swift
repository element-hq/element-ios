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

/**
 Renders multiple chips in a flow layout.
 */
@available(iOS 14.0, *)
struct Chips: View {
    
    @State private var totalHeight: CGFloat = 0
    
    var chips: [String]
    var didDeleteChip: (String) -> Void
    var verticalSpacing: CGFloat = 16
    var horizontalSpacing: CGFloat = 12
    
    var body: some View {
        Group {
            VStack {
                var x = CGFloat.zero
                var y = CGFloat.zero
                GeometryReader { geo in
                    ZStack(alignment: .topLeading, content: {
                        ForEach(chips, id: \.self) { chip in
                            Chip(chip: chip) {
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
                                
                                if chip == chips.last {
                                    // Reset x if it's the last.
                                    x = 0
                                } else {
                                    // Align next chip to the end of the current one.
                                    x -= dimension.width + horizontalSpacing
                                }
                                return result
                            }
                            .alignmentGuide(.top) { dimension in
                                // Use next y value and reset if its the last.
                                let result = y
                                if chip == chips.last {
                                    y = 0
                                }
                                return result
                            }
                        }
                    })
                    .background(viewHeightReader($totalHeight))
                }
            }
            .frame(height: totalHeight)
        }
    }
    
    /**
     As the flow layout uses a `ZStack` and alignmentGuides to overlay the chips we need to use
     Geometry to report back the calculated size
     */
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.frame(in: .local).size.height
            }
            return .clear
        }
    }
}

@available(iOS 14.0, *)
struct Chips_Previews: PreviewProvider {
    static var chips: [String] = ["Chip1", "Chip2", "Chip3", "Chip4", "Chip5", "Chip6"]
    static var previews: some View {
        Group {
            Chips(chips: chips, didDeleteChip: { _ in })
            Chips(chips: chips, didDeleteChip: { _ in })
                .theme(.dark)
        }
        
    }
}
