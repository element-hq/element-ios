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

/// Structure used to pass modules to routers with pop completion blocks.
struct NavigationModule {
    /// Actual presentable of the module
    let presentable: Presentable
    
    /// Block to be called when the module is popped
    let popCompletion: (() -> Void)?
}

//  MARK: - CustomStringConvertible

extension NavigationModule: CustomStringConvertible {
    
    var description: String {
        return "NavigationModule: \(presentable), pop completion: \(String(describing: popCompletion))"
    }
    
}
