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
import SwiftUI
import WysiwygComposer

// MARK: View

/// An item in the toolbar
struct FormatItem {
    /// The type of the item
    let type: FormatType
    /// Whether it is active(highlighted)
    let active: Bool
    /// Whether it is disabled or enabled
    let disabled: Bool
}

/// The types of formatting actions
enum FormatType {
    case bold
    case italic
    case underline
    case strikethrough
    case link
}

extension FormatType: CaseIterable, Identifiable {
    var id: Self { self }
}

extension FormatItem: Identifiable {
    var id: FormatType { type }
}

extension FormatItem {
    /// The icon for the item
    var icon: String {
        switch type {
        case .bold:
            return Asset.Images.bold.name
        case .italic:
            return Asset.Images.italic.name
        case .strikethrough:
            return Asset.Images.strikethrough.name
        case .underline:
            return Asset.Images.underlined.name
        case .link:
            return Asset.Images.link.name
        }
    }
    
    var accessibilityIdentifier: String {
        switch type {
        case .bold:
            return "boldButton"
        case .italic:
            return "italicButton"
        case .strikethrough:
            return "strikethroughButton"
        case .underline:
            return "underlineButton"
        case .link:
            return "linkButton"
        }
    }
    
    var accessibilityLabel: String {
        switch type {
        case .bold:
            return VectorL10n.wysiwygComposerFormatActionBold
        case .italic:
            return VectorL10n.wysiwygComposerFormatActionItalic
        case .strikethrough:
            return VectorL10n.wysiwygComposerFormatActionStrikethrough
        case .underline:
            return VectorL10n.wysiwygComposerFormatActionUnderline
        case .link:
            return VectorL10n.wysiwygComposerFormatActionLink
        }
    }
}

extension FormatType {
    /// Convenience method to map it to the external ViewModel action
    var action: WysiwygAction {
        switch self {
        case .bold:
            return .bold
        case .italic:
            return .italic
        case .strikethrough:
            return .strikeThrough
        case .underline:
            return .underline
        case .link:
            return .link
        }
    }
    
    // TODO: We probably don't need to expose this, clean up.
    /// Convenience method to map it to the external rust binging action
    var composerAction: ComposerAction {
        switch self {
        case .bold:
            return .bold
        case .italic:
            return .italic
        case .strikethrough:
            return .strikeThrough
        case .underline:
            return .underline
        case .link:
            return .link
        }
    }
}

enum ComposerSendMode: Equatable {
    case send
    case edit
    case reply
    case createDM
}

enum ComposerViewAction: Equatable {
    case cancel
    case contentDidChange(isEmpty: Bool)
    case linkTapped(linkAction: LinkAction)
    case storeSelection(selection: NSRange)
}

enum ComposerViewModelResult: Equatable {
    case cancel
    case contentDidChange(isEmpty: Bool)
    case linkTapped(LinkAction: LinkAction)
}

final class LinkActionWrapper: NSObject {
    let linkAction: LinkAction
    
    init(_ linkAction: LinkAction) {
        self.linkAction = linkAction
        super.init()
    }
}


