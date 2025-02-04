// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum AnalyticsServiceError: Error {
    /// The session supplied to the service does not have a state of `MXSessionStateRunning`.
    case sessionIsNotRunning
    /// An error occurred but the session did not report what it was.
    case unknown
}

/// A service responsible for handling the `im.vector.analytics` event from the user's account data.
class AnalyticsService {
    let session: MXSession
    
    /// Creates an analytics service with the supplied session.
    /// - Parameter session: The session to use when reading analytics settings from account data.
    init(session: MXSession) {
        self.session = session
    }
    
    /// The analytics settings for the current user. Calling this method will check whether the settings already
    /// contain an `id` property and if not, will add one to the account data before calling the completion.
    /// - Parameter completion: A completion handler that will be called when the request completes.
    ///
    /// The request will fail if the service's session does not have the `MXSessionStateRunning` state.
    func settings(completion: @escaping (Result<AnalyticsSettings, Error>) -> Void) {
        // Only use the session if it is running otherwise we could wipe out an existing analytics ID.
        guard session.state == .running else {
            MXLog.warning("[AnalyticsService] Aborting attempt to read analytics settings. The session may not be up-to-date.")
            completion(.failure(AnalyticsServiceError.sessionIsNotRunning))
            return
        }
    
        let settings = AnalyticsSettings(accountData: session.accountData)
        
        // The id has already be set so we are done here.
        if settings.id != nil {
            completion(.success(settings))
            return
        }
        
        // Create a new ID and modify the event dictionary.
        let id = UUID().uuidString
        
        var eventDictionary = settings.dictionary
        eventDictionary[AnalyticsSettings.Constants.idKey] = id
        
        session.setAccountData(eventDictionary, forType: AnalyticsSettings.eventType) { [weak self] in
            guard let self = self else {
                completion(.failure(AnalyticsServiceError.unknown))
                return
            }
            
            MXLog.debug("[AnalyticsService] Successfully updated analytics settings in account data.")
            let settings = AnalyticsSettings(accountData: self.session.accountData)
            completion(.success(settings))
        } failure: { error in
            MXLog.warning("[AnalyticsService] Failed to update analytics settings.")
            completion(.failure(error ?? AnalyticsServiceError.unknown))
        }
    }
}
