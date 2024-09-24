// File created from ScreenTemplate
// $ createScreen.sh Contacts ContactDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ContactDetailsCoordinator input parameters
struct ContactDetailsCoordinatorParameters {
    
    /// The displayed contact
    let contact: MXKContact
    
    /// Enable voip call (voice/video). NO by default
    let enableVoipCall: Bool
    
    init(contact: MXKContact,
         enableVoipCall: Bool = false) {
        self.contact = contact
        self.enableVoipCall = enableVoipCall
    }
}
