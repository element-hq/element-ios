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

import Combine
import CoreLocation
import Foundation

/// Location authorization request handler
typealias LocationAuthorizationHandler = (_ authorizationStatus: LocationAuthorizationStatus) -> Void

protocol LocationSharingServiceProtocol {
    /// Request location authorization
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler)
}
