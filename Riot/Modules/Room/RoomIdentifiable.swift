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

/// `RoomIdentifiable` describes an object tied to a specific room id.
/// Useful to identify existing objects that should be removed when the user leaves a room for example.
protocol RoomIdentifiable {
    var roomId: String? { get }
    var threadId: String? { get }
    var mxSession: MXSession? { get }
}
