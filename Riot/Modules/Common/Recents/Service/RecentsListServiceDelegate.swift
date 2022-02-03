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

@objc
public protocol RecentsListServiceDelegate: AnyObject {
    
    /// Delegate method to be called when service data updated
    /// - Parameter service: service object
    /// - Parameter totalCountsChanged: true if total rooms count changed
    @objc optional func recentsListServiceDidChangeData(_ service: RecentsListServiceProtocol,
                                                        totalCountsChanged: Bool)
    
    /// Delegate method to be called when a specific section data updated. Called for each updated section before `recentsListServiceDidChangeData` if implemented.
    /// - Parameter service: service object
    /// - Parameter section: updated section
    /// - Parameter totalCountsChanged: true if total rooms count changed for the section
    @objc optional func recentsListServiceDidChangeData(_ service: RecentsListServiceProtocol,
                                                        forSection section: RecentsListServiceSection,
                                                        totalCountsChanged: Bool)
}
