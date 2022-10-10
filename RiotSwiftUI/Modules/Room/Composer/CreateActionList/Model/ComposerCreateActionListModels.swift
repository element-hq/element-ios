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

@objc enum ComposerCreateAction: Int {
    case photoLibrary
    case stickers
    case attachments
    case polls
    case location
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
        case .polls:
            return VectorL10n.wysiwygComposerStartActionPolls
        case .location:
            return VectorL10n.wysiwygComposerStartActionLocation
        case .camera:
            return VectorL10n.wysiwygComposerStartActionCamera
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
        case .polls:
            return Asset.Images.actionPoll.name
        case .location:
            return Asset.Images.actionLocation.name
        case .camera:
            return Asset.Images.actionCamera.name
        }
    }
}

struct ComposerCreateActionListViewState: BindableState {
    let actions: [ComposerCreateAction]
}

enum ComposerCreateActionListViewModelResult: Equatable {
    case done(ComposerCreateAction)
}
