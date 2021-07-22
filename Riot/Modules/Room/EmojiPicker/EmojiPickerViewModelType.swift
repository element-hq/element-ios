// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
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

protocol EmojiPickerViewModelViewDelegate: AnyObject {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didUpdateViewState viewSate: EmojiPickerViewState)
}

protocol EmojiPickerViewModelCoordinatorDelegate: AnyObject {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModelDidCancel(_ viewModel: EmojiPickerViewModelType)
}

/// Protocol describing the view model used by `EmojiPickerViewController`
protocol EmojiPickerViewModelType {
            
    var viewDelegate: EmojiPickerViewModelViewDelegate? { get set }
    var coordinatorDelegate: EmojiPickerViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EmojiPickerViewAction)
}
