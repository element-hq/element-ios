// 
// Copyright 2023 New Vector Ltd
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

import UIKit
import WysiwygComposer

/// Defines behaviour for an object that is able to manage views created
/// by a `NSTextAttachmentViewProvider`. This can be implemented
/// by an `UITextView` that would keep track of views in order to
/// (internally) clear them when required (e.g. when setting a new attributed text).
///
/// Note: It is necessary to clear views manually due to a bug in iOS. See `MXKMessageTextView`.
@available(iOS 15.0, *)
protocol PillViewFlusher: AnyObject {
    /// Register a pill view that has been added through `NSTextAttachmentViewProvider`.
    /// Should be called within the `loadView` function in order to clear the pills properly on text updates.
    ///
    /// - Parameter pillView: View to register.
    func registerPillView(_ pillView: UIView)
}

@available(iOS 15.0, *)
extension MXKMessageTextView: PillViewFlusher { }

@available(iOS 15.0, *)
extension WysiwygTextView: PillViewFlusher { }
