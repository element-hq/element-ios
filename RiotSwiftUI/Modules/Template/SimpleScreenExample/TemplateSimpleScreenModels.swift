//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum TemplateSimpleScreenPromptType {
    case regular
    case upgrade
}

extension TemplateSimpleScreenPromptType: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .regular:
            return VectorL10n.roomCreationMakePublicPromptTitle
        case .upgrade:
            return VectorL10n.roomDetailsHistorySectionPromptTitle
        }
    }
    
    var image: ImageAsset {
        switch self {
        case .regular:
            return Asset.Images.appSymbol
        case .upgrade:
            return Asset.Images.keyVerificationSuccessShield
        }
    }
}

// MARK: View model

enum TemplateSimpleScreenViewModelResult {
    case accept
    case cancel
}

// MARK: View

struct TemplateSimpleScreenViewState: BindableState {
    var promptType: TemplateSimpleScreenPromptType
    var count: Int
}

enum TemplateSimpleScreenViewAction {
    case incrementCount
    case decrementCount
    case accept
    case cancel
}
