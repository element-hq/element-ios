/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
