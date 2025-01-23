//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

protocol TemplateRoomChatServiceProtocol {
    var roomInitializationStatus: CurrentValueSubject<TemplateRoomChatRoomInitializationStatus, Never> { get }
    var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never> { get }
    var roomName: String? { get }
    func send(textMessage: String)
}
