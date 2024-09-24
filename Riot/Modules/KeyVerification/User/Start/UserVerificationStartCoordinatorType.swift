// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol UserVerificationStartCoordinatorDelegate: AnyObject {
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest)        
    
    func userVerificationStartCoordinatorDidCancel(_ coordinator: UserVerificationStartCoordinatorType)
}

/// `UserVerificationStartCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol UserVerificationStartCoordinatorType: Coordinator, Presentable {
    var delegate: UserVerificationStartCoordinatorDelegate? { get }
}
