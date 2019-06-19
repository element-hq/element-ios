/*
 Copyright 2019 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

protocol ReactionsMenuViewModelDelegate: class {
    func reactionsMenuViewModelDidUpdate(_ viewModel: ReactionsMenuViewModelType)
}

@objc protocol ReactionsMenuViewModelCoordinatorDelegate: class {
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didAddReaction reaction: String, forEventId eventId: String)
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didRemoveReaction reaction: String, forEventId eventId: String)
}


protocol ReactionsMenuViewModelType {

    var isAgreeButtonSelected: Bool { get }
    var isDisagreeButtonSelected: Bool { get }
    var isLikeButtonSelected: Bool { get }
    var isDislikeButtonSelected: Bool { get }

    var viewDelegate: ReactionsMenuViewModelDelegate? { get set }
    var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate? { get set }

    func process(viewAction: ReactionsMenuViewAction)
}
