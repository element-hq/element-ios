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

enum RoomReactionsViewAction {
    case loadData
    case tapReaction(index: Int)
    case addNewReaction
    case tapShowAction(action: ShowAction)
    case longPress

    enum ShowAction {
        case showAll
        case showLess
        case addReaction
    }
}

enum RoomReactionsViewState {
    case loaded(reactionsViewData: [RoomReactionViewData], remainingViewData: [RoomReactionViewData], showAllButtonState: ShowAllButtonState, showAddReaction: Bool)

    enum ShowAllButtonState {
        case none
        case showAll
        case showLess
    }
}

@objc protocol RoomReactionsViewModelDelegate: AnyObject {
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didAddReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didRemoveReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didShowAllTappedForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didShowLessTappedForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didTapAddReactionForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didLongPressForEventId eventId: String)
}

protocol RoomReactionsViewModelViewDelegate: AnyObject {
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didUpdateViewState viewState: RoomReactionsViewState)
}

protocol RoomReactionsViewModelType {
    var viewModelDelegate: RoomReactionsViewModelDelegate? { get set }
    var viewDelegate: RoomReactionsViewModelViewDelegate? { get set }
    
    func process(viewAction: RoomReactionsViewAction)
}
