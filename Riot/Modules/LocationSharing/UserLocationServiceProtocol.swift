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

/// Describes service that monitor and share current user device location to rooms where user shared is location
protocol UserLocationServiceProtocol {
    
    /// Request location permissions that enables live location sharing
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler)

    /// Start monitoring user location and look to rooms where location should be sent
    func start()
    
    /// Stop monitoring user location
    func stop()
}
