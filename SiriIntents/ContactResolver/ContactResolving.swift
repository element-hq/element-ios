// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Intents

@objc protocol ContactResolving {
    func resolveContacts(_ contacts: [INPerson]?,
                         withCompletion completion: @escaping ([INPersonResolutionResult]) -> Void)
}
