/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// Paswword strength
enum PasswordStrength: UInt {
    
    case tooGuessable
    case veryGuessable
    case somewhatGuessable
    case safelyUnguessable
    case veryUnguessable
}
