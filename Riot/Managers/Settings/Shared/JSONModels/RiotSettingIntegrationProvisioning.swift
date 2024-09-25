/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// Model for "im.vector.setting.integration_provisioning"
/// https://github.com/vector-im/riot-meta/blob/master/spec/settings.md#selecting-no-provisioning-for-integration-managers
struct RiotSettingIntegrationProvisioning {
    let enabled: Bool
}

extension RiotSettingIntegrationProvisioning: Decodable {
    enum CodingKeys: String, CodingKey {
        case enabled
    }
}
