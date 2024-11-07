//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import DesignKit
import Foundation

protocol ThemeSwiftUI: ThemeSwiftUIType {
    var identifier: ThemeIdentifier { get }
    var isDark: Bool { get }
}
