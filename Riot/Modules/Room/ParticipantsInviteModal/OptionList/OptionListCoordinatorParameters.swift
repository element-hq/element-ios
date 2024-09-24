// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// OptionListCoordinator input parameters
struct OptionListCoordinatorParameters {
    
    let title: String?
    let options: [OptionListItemViewData]
    
    let navigationRouter: NavigationRouterType?

}
