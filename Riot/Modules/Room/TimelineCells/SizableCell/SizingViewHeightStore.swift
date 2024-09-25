/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation

/// `SizingViewHeightStore` allows to store `SizingViewHeight` for a given hash value
final class SizingViewHeightStore {
    
    private var sizes = Set<SizingViewHeight>()
    
    func findOrCreateSizingViewHeight(from viewHeightHashValue: Int) -> SizingViewHeight {
        
        let sizingViewHeight: SizingViewHeight
        
        if let foundSizingViewHeight = self.sizes.first(where: { (sizingViewHeight) -> Bool in
            return sizingViewHeight.uniqueIdentifier == viewHeightHashValue
        }) {
            sizingViewHeight = foundSizingViewHeight
        } else {
            sizingViewHeight = SizingViewHeight(uniqueIdentifier: viewHeightHashValue)
            self.sizes.insert(sizingViewHeight)
        }
        
        return sizingViewHeight
    }
}
