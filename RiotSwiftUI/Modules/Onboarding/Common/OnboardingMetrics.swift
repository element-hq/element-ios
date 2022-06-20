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

/// Metrics used across the entire onboarding flow.
struct OnboardingMetrics {
    static let maxContentHeight: CGFloat = 750
    
    /// The padding used between the top of the main content and the navigation bar.
    static let topPaddingToNavigationBar: CGFloat = 16
    /// The padding used between the footer and the bottom of the view.
    static let actionButtonBottomPadding: CGFloat = 24
    /// The width/height used for the main icon shown in most of the screens.
    static let iconSize: CGFloat = 90
    
    /// The padding used to the top of the view for breaker screens that don't have a navigation bar.
    static let breakerScreenTopPadding: CGFloat = 80
    static let breakerScreenIconBottomPadding: CGFloat = 42
    
    /// The height to use for top/bottom spacers to pad the views to fit the `maxContentHeight`.
    static func spacerHeight(in geometry: GeometryProxy) -> CGFloat {
        max(0, (geometry.size.height - maxContentHeight) / 2)
    }
}
