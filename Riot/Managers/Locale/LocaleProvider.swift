// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/**
 Provides the locale logic for Riot app based on mx languages.
 */
class LocaleProvider: LocaleProviderType {
    static var locale: Locale? {
        if let localeIdentifier = Bundle.mxk_language() {
           return Locale(identifier: localeIdentifier)
        } else if let fallbackLocaleIdentifier = Bundle.mxk_fallbackLanguage() {
           return Locale(identifier: fallbackLocaleIdentifier)
        }
        return nil
    }
}
