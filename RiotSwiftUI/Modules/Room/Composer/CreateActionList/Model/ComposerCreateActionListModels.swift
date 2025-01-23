//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
