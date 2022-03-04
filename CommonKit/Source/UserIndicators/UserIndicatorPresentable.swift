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

/// A presenter associated with and called by a `UserIndicator`, and responsible for the underlying view shown on the screen.
public protocol UserIndicatorViewPresentable {
    /// Called when the `UserIndicator` is started (manually or by the `UserIndicatorQueue`)
    func present()
    /// Called when the `UserIndicator` is manually cancelled or completed
    func dismiss()
}

