// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Sentry
import MatrixSDK

/// Sentry client used as part of the Analytics set of tools to track health metrics
/// of the application, such as crashes, non-fatal issues and performance.
///
/// All analytics tracking, incl. health metrics, is subject to user consent,
/// configurable in user settings.
struct SentryMonitoringClient {
    private static let sentryDSN = "https://a5e37731f9b94642a1b93093cacbee4c@sentry.tools.element.io/47"
    
    func start() {
        guard !SentrySDK.isEnabled else { return }
        
        MXLog.debug("[SentryMonitoringClient] Started")
        SentrySDK.start { options in
            options.dsn = Self.sentryDSN
            
            // Collecting only 10% of all events
            options.sampleRate = 0.1
            options.tracesSampleRate = 0.1
            
            // Disable unnecessary network tracking
            options.enableNetworkBreadcrumbs = false
            options.enableNetworkTracking = false
            
            options.beforeSend = { event in
                // Use the actual error message as issue fingerprint
                if let message = event.message?.formatted {
                    event.fingerprint = [message]
                }
                MXLog.debug("[SentryMonitoringClient] Issue detected: \(event)")
                return event
            }

            options.onCrashedLastRun = { event in
                MXLog.debug("[SentryMonitoringClient] Last run crashed: \(event)")
            }
        }
    }
    
    func stop() {
        MXLog.debug("[SentryMonitoringClient] Stopped")
        SentrySDK.close()
    }
    
    func reset() {
        MXLog.debug("[SentryMonitoringClient] Reset")
        SentrySDK.startSession()
    }
    
    func trackNonFatalIssue(_ issue: String, details: [String: Any]?) {
        guard SentrySDK.isEnabled else { return }
        
        let event = Event()
        event.level = .error
        event.message = .init(formatted: issue)
        event.extra = details
        SentrySDK.capture(event: event)
    }
    
    func startPerformanceTracking(name: String, operation: String) -> StopDurationTracking {
        let transaction = SentrySDK.startTransaction(name: name, operation: operation)
        return {
            transaction.finish()
        }
    }
}
