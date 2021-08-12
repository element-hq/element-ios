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

import Foundation
import SwiftUI

/**
 Used to modify the visibilty of a SwiftUI view.
 `hidden` naming historically on iOS refers to a view that is not visible but is included in layout/constraints. i.e. takes up the space.
 `gone` here refers to a view that is invisible and does not contribute to layout. Android uses the same naming as this.
 */
@available(iOS 14.0, *)
enum Visbility: Int {
    case visible
    case hidden
    case gone
}

@available(iOS 14.0, *)
struct VisbilityModifier: ViewModifier {
    var visibilty: Visbility
    func body(content: Content) -> some View {
        if visibilty == .visible {
            content
        } else if visibilty == .hidden {
            content.hidden()
        }
    }
}

@available(iOS 14.0, *)
extension View {
    func hidden(_ invisible: Bool) -> some View {
        self.modifier(VisbilityModifier(visibilty: invisible ? .hidden : .visible))
    }

    func gone(_ hidden: Bool) -> some View {
        self.modifier(VisbilityModifier(visibilty: hidden ? .gone : .visible))
    }
    
    func visbility(_ visibility: Visbility) -> some View {
        self.modifier(VisbilityModifier(visibilty: visibility))
    }
}
