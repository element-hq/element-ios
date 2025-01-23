//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class TemplateUserProfileService: TemplateUserProfileServiceProtocol {
    private let session: MXSession
    private var listenerReference: Any?
    
    var userId: String {
        session.myUser.userId
    }
    
    var displayName: String? {
        session.myUser.displayname
    }
    
    var avatarUrl: String? {
        session.myUser.avatarUrl
    }
    
    private(set) var presenceSubject: CurrentValueSubject<TemplateUserProfilePresence, Never>
    
    init(session: MXSession) {
        self.session = session
        presenceSubject = CurrentValueSubject(TemplateUserProfilePresence(mxPresence: session.myUser.presence))
        listenerReference = setupPresenceListener()
    }

    deinit {
        guard let reference = listenerReference else { return }
        session.myUser.removeListener(reference)
    }
    
    func setupPresenceListener() -> Any? {
        let reference = session.myUser.listen { [weak self] event in
            guard let self = self,
                  let event = event,
                  case .presence = MXEventType(identifier: event.eventId)
            else { return }
            self.presenceSubject.send(TemplateUserProfilePresence(mxPresence: self.session.myUser.presence))
        }
        if reference == nil {
            UILog.error("[TemplateUserProfileService] Did not recieve a lisenter reference.")
        }
        return reference
    }
}

private extension TemplateUserProfilePresence {
    init(mxPresence: MXPresence) {
        switch mxPresence {
        case .online:
            self = .online
        case .unavailable:
            self = .idle
        case .offline, .unknown:
            self = .offline
        default:
            self = .offline
        }
    }
}
