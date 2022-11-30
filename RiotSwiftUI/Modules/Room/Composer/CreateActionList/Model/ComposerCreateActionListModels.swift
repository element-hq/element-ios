//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

// MARK: View model

enum ComposerCreateActionListViewAction {
    // The user selected an action
    case selectAction(ComposerCreateAction)
    // The user toggled the text formatting action
    case toggleTextFormatting(Bool)
}

enum ComposerCreateActionListViewModelResult: Equatable {
    // The user selected an action and is done with the screen
    case done(ComposerCreateAction)
    // The user toggled the text formatting setting but might not be done with the screen
    case toggleTextFormatting(Bool)
}

// MARK: View

struct ComposerCreateActionListViewState: BindableState {
    /// The list of composer create actions to display to the user
    let actions: [ComposerCreateAction]
    let wysiwygEnabled: Bool
    let isScrollingEnabled: Bool

    var bindings: ComposerCreateActionListBindings
}

struct ComposerCreateActionListBindings {
    var textFormattingEnabled: Bool
}

@objc enum ComposerCreateAction: Int {
    /// Upload a photo/video from the media library
    case photoLibrary
    /// Add a sticker
    case stickers
    /// Upload an attachment
    case attachments
    /// Voice broadcast
    case voiceBroadcast
    /// Create a Poll
    case polls
    /// Add a location
    case location
    /// Upload a photo or video from the camera
    case camera
}

extension ComposerCreateAction: Equatable, CaseIterable, Identifiable {
    var id: Self { self }
}

extension ComposerCreateAction {
    var title: String {
        switch self {
        case .photoLibrary:
            return VectorL10n.wysiwygComposerStartActionMediaPicker
        case .stickers:
            return VectorL10n.wysiwygComposerStartActionStickers
        case .attachments:
            return VectorL10n.wysiwygComposerStartActionAttachments
        case .voiceBroadcast:
            return VectorL10n.wysiwygComposerStartActionVoiceBroadcast
        case .polls:
            return VectorL10n.wysiwygComposerStartActionPolls
        case .location:
            return VectorL10n.wysiwygComposerStartActionLocation
        case .camera:
            return VectorL10n.wysiwygComposerStartActionCamera
        }
    }
    
    var accessibilityIdentifier: String {
        switch self {
        case .photoLibrary:
            return "photoLibraryAction"
        case .stickers:
            return "stickersAction"
        case .attachments:
            return "attachmentsAction"
        case .voiceBroadcast:
            return "voiceBroadcastAction"
        case .polls:
            return "pollsAction"
        case .location:
            return "locationAction"
        case .camera:
            return "cameraAction"
        }
    }
    
    var icon: String {
        switch self {
        case .photoLibrary:
            return Asset.Images.actionMediaLibrary.name
        case .stickers:
            return Asset.Images.actionSticker.name
        case .attachments:
            return Asset.Images.actionFile.name
        case .voiceBroadcast:
            return Asset.Images.actionLive.name
        case .polls:
            return Asset.Images.actionPoll.name
        case .location:
            return Asset.Images.actionLocation.name
        case .camera:
            return Asset.Images.actionCamera.name
        }
    }
}
