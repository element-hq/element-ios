// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CryptoKit

/// Object encapsulating an experiment with an arbitrary number of variants, and a method to deterministically
/// and uniformly assign a variant to user. Variants do not carry any implicit semantics, they are plain numbers
/// to be interpreted by the caller of the experiment.
struct Experiment {
    let name: String
    let variants: UInt
    
    /// Get the assigned variant from the total number of variants and for a given `userId`
    ///
    /// This variant is chosen deterministically (the same `userId` and experiment `name` will yield the same variant)
    /// and uniformly (multiple users are distributed roughly evenly among the variants).
    func variant(userId: String) -> UInt {
        // Combine user id with experiment name to avoid identical variant
        // for the same user in different experiments
        let data = (userId + name).data(using: .utf8) ?? Data()
        
        // Get the first 8 bytes and map to decimal number (UInt64 = 8 bytes)
        let decimal = digest(for: data)
            .prefix(8)
            .reduce(0) { $0 << 8 | UInt64($1) }
        
        // Compress the decimal into a set number of variants using modulo
        return UInt(decimal % UInt64(variants))
    }
    
    private func digest(for data: Data) -> SHA256.Digest {
        var sha = SHA256()
        sha.update(data: data)
        return sha.finalize()
    }
}
