/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// TemplateScreenViewController view state
enum TemplateScreenViewState {
    case idle
    case loading
    case loaded(_ displayName: String)
    case error(Error)
}
