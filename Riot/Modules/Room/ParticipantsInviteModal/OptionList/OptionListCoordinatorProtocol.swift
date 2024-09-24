// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol OptionListCoordinatorDelegate: AnyObject {
    func optionListCoordinator(_ coordinator: OptionListCoordinatorProtocol, didSelectOptionAt index: Int)
    func optionListCoordinatorDidCancel(_ coordinator: OptionListCoordinatorProtocol)
}

/// `OptionListCoordinatorProtocol` is a protocol describing a Coordinator that handle invite options screen navigation flow.
protocol OptionListCoordinatorProtocol: Coordinator, Presentable {
    var delegate: OptionListCoordinatorDelegate? { get }
}
