/*
 Copyright 2019 New Vector Ltd
 
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

/// `SizingViewHeight` allows to associate a height for a given width to a unique value.
final class SizingViewHeight: Hashable, Equatable, CustomStringConvertible {
    
    // MARK: - Properties
    
    let uniqueIdentifier: Int
    var heights: [CGFloat /* width */: CGFloat /* height */] = [:]
    
    var description: String {
        return "<\(type(of: self))> uniqueIdentifier: \(uniqueIdentifier) - heights: \(heights)"
    }
    
    // MARK: - Setup
    
    init(uniqueIdentifier: Int) {
        self.uniqueIdentifier = uniqueIdentifier
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.uniqueIdentifier)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: SizingViewHeight, rhs: SizingViewHeight) -> Bool {
        return lhs.uniqueIdentifier == rhs.uniqueIdentifier
    }
}
