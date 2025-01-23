// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Object enabling a phased rollout of features depending on the `userId` and `targetPercentage`.
///
/// The feature uses an experiment under the hood with 100 variants representing 100%.
/// Each userId is deterministically and uniformly assigned a variant, and depending
/// on whether this falls below or above the `targetPercentage` threshold, the feature
/// is considered enabled or disabled.
struct PhasedRolloutFeature {
    private let experiment: Experiment
    private let targetPercentage: Double
    
    init(name: String, targetPercentage: Double) {
        self.experiment = .init(
            name: name,
            // 100 variants where each variant represents a single percentage
            variants: 100
        )
        self.targetPercentage = targetPercentage
    }
    
    func isEnabled(userId: String) -> Bool {
        // Get a bucket number between 0-99
        let variant = experiment.variant(userId: userId)
        // Convert to a percentage
        let percentage = Double(variant) / 100
        // Consider enabled if falls below rollout target
        return percentage < targetPercentage
    }
}
