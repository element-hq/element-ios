// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// EnterPinCodeViewController view state
enum EnterPinCodeViewState {
    case choosePin              //  creating pin for the first time, enter for first
    case choosePinAfterLogin    //  creating pin for the first time, after login, enter for first
    case choosePinAfterRegister //  creating pin for the first time, after registration, enter for first
    case notAllowedPin          //  creating pin for the first time, provided pin is not allowed
    case confirmPin             //  creating pin for the first time, confirm
    case pinsDontMatch          //  pins don't match
    case unlock                 //  after pin has been set, enter pin to unlock
    case wrongPin               //  after pin has been set, pin entered wrongly
    case wrongPinTooManyTimes   //  after pin has been set, pin entered wrongly too many times
    case forgotPin              //  after pin has been set, user tapped forgot pin
    case confirmPinToDisable    //  after pin has been set, confirm pin to disable pin
    case inactive               //  inactive state, only used when app is not active
    case changePin              //  pin is set, user tapped change pin from settings
}
