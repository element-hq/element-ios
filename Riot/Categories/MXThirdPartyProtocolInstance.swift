// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension MXThirdPartyProtocolInstance {
    
    open override func jsonDictionary() -> [AnyHashable: Any]! {
        return [
            "network_id": networkId as Any,
            "fields": fields as Any,
            "instance_id": instanceId as Any,
            "desc": desc as Any,
            "bot_user_id": botUserId as Any,
            "icon": icon as Any
        ]
    }
}
