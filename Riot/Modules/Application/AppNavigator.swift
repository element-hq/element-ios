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
import CommonKit

/// Type of indicator to be shown in the app navigator
enum AppUserIndicatorType {
    /// Loading toast with custom label
    case loading(String)
    
    /// Success toast with custom label
    case success(String)
}

/// AppNavigatorProtocol abstract a navigator at app level.
/// It enables to perform the navigation within the global app scope (open the side menu, open a room and so on)
/// Note: Presentation of the pattern here https://www.swiftbysundell.com/articles/navigation-in-swift/#where-to-navigator
protocol AppNavigatorProtocol {
    
    var sideMenu: SideMenuPresentable { get }
    
    /// Navigate to a destination screen or a state
    /// Do not use protocol with associatedtype for the moment like presented here https://www.swiftbysundell.com/articles/navigation-in-swift/#where-to-navigator use a separate enum
    func navigate(to destination: AppNavigatorDestination)
    
    /// Add new indicator, such as loading spinner or a success message, to an app-wide queue of other indicators
    ///
    /// If the queue is empty, the indicator will be displayed immediately, otherwise it will be pending
    /// until the previously added indicator have completed / been cancelled.
    ///
    /// To remove an indicator, cancel or deallocate the returned `UserIndicator`
    func addUserIndicator(_ type: AppUserIndicatorType) -> UserIndicator
}
