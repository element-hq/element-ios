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

@available(iOS 14.0, *)
struct Chips: View {
    
    var chips: [String]
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return GeometryReader { geo in
                ZStack(alignment: .topLeading, content: {
                    ForEach(chips, id: \.self) { chip in
                        Chip(titleKey: chip) {
                            
                        }
                        .padding(.all, 5)
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geo.size.width {
                                width = 0
                                height -= dimension.height
                            }
                            
                            let result = width
                            if chip == chips.last {
                                width = 0
                            } else {
                                width -= dimension.width
                            }
                            return result
                          }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if chip == chips.last {
                                height = 0
                            }
                            return result
                        }
                }
            })
        }.padding(.all, 10)
    }
}

@available(iOS 14.0, *)
struct Chips_Previews: PreviewProvider {
    static var previews: some View {
        Chips(chips: ["Chip1", "Chip2", "Chip3", "Chip4", "Chip5", "Chip6"])
            .frame(width: .infinity, height: 400, alignment: .leading)
    }
}
