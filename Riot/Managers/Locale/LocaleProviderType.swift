// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/**
 Used to provide an application/target specific locale.
 */
protocol LocaleProviderType {
    static var locale: Locale? { get }
}
