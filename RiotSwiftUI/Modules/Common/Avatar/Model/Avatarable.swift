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

/// A protocol that any class or struct can conform to
/// so that it can easily produce avatar data.
///
/// E.g. MXRoom, MxUser can conform to this making it
/// easy to grab the avatar data for display.
protocol Avatarable: AvatarInputProtocol { }
extension Avatarable {
    var avatarData: AvatarInput {
        AvatarInput(
            mxContentUri: mxContentUri,
            matrixItemId: matrixItemId,
            displayName: displayName
        )
    }
}
