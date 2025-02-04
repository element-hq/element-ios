//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol TimelinePollViewModelProtocol {
    var context: TimelinePollViewModelType.Context { get }
    var completion: ((TimelinePollViewModelResult) -> Void)? { get set }
    
    func updateWithPollDetailsState(_ pollDetailsState: TimelinePollDetailsState)
    func showAnsweringFailure()
    func showClosingFailure()
}
