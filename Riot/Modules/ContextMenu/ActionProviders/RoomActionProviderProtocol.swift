// 
// Copyright 2022 New Vector Ltd
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

/// Classes compliant with the protocol `RoomActionProviderProtocol` are meant to provide the menu within `UIContextMenuActionProvider`
@available(iOS 13.0, *)
protocol RoomActionProviderProtocol {
    /// menu instance returned within the `UIContextMenuActionProvider` block
    var menu: UIMenu { get }
}
