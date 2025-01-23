// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Protocol to be used with a `CustomSizedPresentationController`
@objc protocol CustomSizedPresentable {
    
    /// Custom size for presentable. If not implemented, the presentable will have the both half width and height of the container view.
    /// - Parameter containerSize: Container view's size.
    @objc optional func customSize(withParentContainerSize containerSize: CGSize) -> CGSize
    
    /// Position (origin) of presentable in container. If not implemented, the presentable will be centered to the container view.
    /// - Parameter containerSize: Container view's size.
    @objc optional func position(withParentContainerSize containerSize: CGSize) -> CGPoint
    
}
