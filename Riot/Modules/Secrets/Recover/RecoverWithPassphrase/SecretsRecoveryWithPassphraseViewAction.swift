/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsRecoveryWithPassphraseViewController view actions exposed to view model
enum SecretsRecoveryWithPassphraseViewAction {
    case recover
    case useRecoveryKey
    case resetSecrets
    case cancel
}
