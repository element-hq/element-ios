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
    /// The state of the item
    let state: ActionState
}

/// The types of formatting actions
enum FormatType {
    case bold
    case italic
    case underline
    case strikethrough
    case unorderedList
    case orderedList
    case indent
    case unindent
    case inlineCode
    case codeBlock
    case quote
    case link
}

extension FormatType: CaseIterable, Identifiable {
    var id: Self { self }
}

extension FormatType {
    /// Return true if the format type is an indentation action.
    var isIndentType: Bool {
        switch self {
        case .indent, .unindent:
            return true
        default:
            return false
        }
    }
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
        case .underline:
            return Asset.Images.underlined.name
        case .strikethrough:
            return Asset.Images.strikethrough.name
        case .unorderedList:
            return Asset.Images.bulletList.name
        case .orderedList:
            return Asset.Images.numberedList.name
        case .indent:
            return Asset.Images.indentIncrease.name
        case .unindent:
            return Asset.Images.indentDecrease.name
        case .inlineCode:
            return Asset.Images.code.name
        case .codeBlock:
            return Asset.Images.codeBlock.name
        case .quote:
            return Asset.Images.quote.name
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
        case .underline:
            return "underlineButton"
        case .strikethrough:
            return "strikethroughButton"
        case .unorderedList:
            return "unorderedListButton"
        case .orderedList:
            return "orderedListButton"
        case .indent:
            return "indentListButton"
        case .unindent:
            return "unIndentButton"
        case .inlineCode:
            return "inlineCodeButton"
        case .codeBlock:
            return "codeBlockButton"
        case .quote:
            return "quoteButton"
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
        case .underline:
            return VectorL10n.wysiwygComposerFormatActionUnderline
        case .strikethrough:
            return VectorL10n.wysiwygComposerFormatActionStrikethrough
        case .unorderedList:
            return VectorL10n.wysiwygComposerFormatActionUnorderedList
        case .orderedList:
            return VectorL10n.wysiwygComposerFormatActionOrderedList
        case .indent:
            return VectorL10n.wysiwygComposerFormatActionIndent
        case .unindent:
            return VectorL10n.wysiwygComposerFormatActionUnIndent
        case .inlineCode:
            return VectorL10n.wysiwygComposerFormatActionInlineCode
        case .codeBlock:
            return VectorL10n.wysiwygComposerFormatActionCodeBlock
        case .quote:
            return VectorL10n.wysiwygComposerFormatActionQuote
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
        case .underline:
            return .underline
        case .strikethrough:
            return .strikeThrough
        case .unorderedList:
            return .unorderedList
        case .orderedList:
            return .orderedList
        case .indent:
            return .indent
        case .unindent:
            return .unindent
        case .inlineCode:
            return .inlineCode
        case .codeBlock:
            return .codeBlock
        case .quote:
            return .quote
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
        case .underline:
            return .underline
        case .strikethrough:
            return .strikeThrough
        case .unorderedList:
            return .unorderedList
        case .orderedList:
            return .orderedList
        case .indent:
            return .indent
        case .unindent:
            return .unindent
        case .inlineCode:
            return .inlineCode
        case .codeBlock:
            return .codeBlock
        case .quote:
            return .quote
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
