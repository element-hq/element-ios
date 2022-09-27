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

/// A modifier for showing the activity indicator centered over a view.
struct ActivityIndicatorModifier: ViewModifier {
    var show: Bool
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .overlay(activityIndicator, alignment: .center)
    }
    
    @ViewBuilder
    private var activityIndicator: some View {
        if show {
            ActivityIndicator()
        }
    }
}

extension View {
    func activityIndicator(show: Bool) -> some View {
        modifier(ActivityIndicatorModifier(show: show))
    }
}
