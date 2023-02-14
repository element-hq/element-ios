// 
// Copyright 2023 New Vector Ltd
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
