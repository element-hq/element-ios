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

protocol AuthenticationLoginViewModelProtocol {
    
    var callback: (@MainActor (AuthenticationLoginViewModelResult) -> Void)? { get set }
    var context: AuthenticationLoginViewModelType.Context { get }
    
    /// Update the view to reflect that a new homeserver is being loaded.
    @MainActor func update(isLoading: Bool)
    
    /// Update the view with new homeserver information.
    @MainActor func update(homeserver: AuthenticationHomeserverViewData)
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationLoginErrorType)
}
