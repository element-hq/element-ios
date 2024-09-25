/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

enum SettingsKeyBackupViewAction {
    case load
    case create
    case restore(MXKeyBackupVersion)
    case confirmDelete(MXKeyBackupVersion)
    case delete(MXKeyBackupVersion)
}
