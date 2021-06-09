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

/// AppNavigatorProtocol abstract a navigator at app level.
/// It enables to perform the navigation within the global app scope (open the side menu, open a room and so on)
/// Note: Use a destination enum like presented here https://www.swiftbysundell.com/articles/navigation-in-swift/#where-to-navigator or use simple methods like Element Android Navigator
protocol AppNavigatorProtocol {
    
    var sideMenu: SideMenuPresentable { get }
    var alert: AlertPresentable { get }
}
