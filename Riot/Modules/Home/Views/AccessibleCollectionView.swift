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
