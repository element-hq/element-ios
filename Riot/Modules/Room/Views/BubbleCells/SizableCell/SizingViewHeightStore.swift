/*
Copyright 2020 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
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
