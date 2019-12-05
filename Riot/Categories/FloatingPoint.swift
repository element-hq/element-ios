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

extension FloatingPoint {
    
    /// Returns clamped `self` value.
    /// https://gist.github.com/laevandus/6fd35992157fcc9b5660bcbc82ebfb52#file-clampfloatingpoint-swift
    ///
    /// - Parameter range: The closed range in which `self` should be clamped (`0.2...3.3` for example).
    /// - Returns: A FloatingPoint clamped value.
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}
