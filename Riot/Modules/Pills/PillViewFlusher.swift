// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
