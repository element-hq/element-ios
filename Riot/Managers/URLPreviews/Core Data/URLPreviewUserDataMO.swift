// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreData

extension URLPreviewUserDataMO {
    convenience init(context: NSManagedObjectContext, eventID: String, roomID: String, dismissed: Bool) {
        self.init(context: context)
        self.eventID = eventID
        self.roomID = roomID
        self.dismissed = dismissed
    }
}
