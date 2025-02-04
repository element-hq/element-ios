// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol ComposerViewModelProtocol {
    var context: ComposerViewModelType.Context { get }
    var callback: ((ComposerViewModelResult) -> Void)? { get set }
    var sendMode: ComposerSendMode { get set }
    var textFormattingEnabled: Bool { get set }
    var eventSenderDisplayName: String? { get set }
    var placeholder: String? { get set }
    var isFocused: Bool { get }
    var isLandscapePhone: Bool { get set }
    var selectionToRestore: NSRange? { get }
    
    func dismissKeyboard()
    func showKeyboard()
}
