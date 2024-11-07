// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

/// A collection view that returns an accessibility element count equal to the number of
/// items in its first section. This allows voiceover user to swipe through the entire collection.
class AccessibleCollectionView: UICollectionView {
    private var numberOfItemsInFirstSection = 0
    
    override func accessibilityElementCount() -> Int {
        return numberOfItemsInFirstSection
    }
    
    override func numberOfItems(inSection section: Int) -> Int {
        let numberOfItems = super.numberOfItems(inSection: section)
        
        if section == 0 {
            numberOfItemsInFirstSection = numberOfItems
        }
        
        return numberOfItems
    }
}
