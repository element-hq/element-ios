// 
// Copyright 2021 New Vector Ltd
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
import MatrixSDK
import Combine

struct UISIAutoReportData {
    let eventId: String?
    let roomId: String?
    let senderKey: String?
    let deviceId: String?
    let userId: String?
    let sessionId: String?
}

extension UISIAutoReportData: Codable {
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case roomId = "room_id"
        case senderKey = "sender_key"
        case deviceId = "device_id"
        case userId = "user_id"
        case sessionId = "session_id"
    }
}


/// Listens for failed decryption events and silently sends reports RageShake server.
/// Also requests that message senders send a matching report to have both sides of the interaction.
@objcMembers class UISIAutoReporter: NSObject, UISIDetectorDelegate {
    
    struct ReportInfo: Hashable {
        let roomId: String
        let sessionId: String
    }
    
    // MARK: - Properties
    
    private static let autoRsRequest = "im.vector.auto_rs_request"
    private static let reportSpacing = 60
    
    private let bugReporter: MXBugReportRestClient
    private let dispatchQueue = DispatchQueue(label: "io.element.UISIAutoReporter.queue")
    // Simple in memory cache of already sent report
    private var alreadyReportedUisi = Set<ReportInfo>()
    private let e2eDetectedSubject = PassthroughSubject<UISIDetectedMessage, Never>()
    private let matchingRSRequestSubject = PassthroughSubject<MXEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var sessions = [MXSession]()
    private var enabled = false {
        didSet {
            guard oldValue != enabled else { return }
            detector.enabled = enabled
        }
    }
    
    // MARK: - Setup
    
    override init() {
        self.bugReporter =  MXBugReportRestClient.vc_bugReportRestClient(appName: BuildSettings.bugReportUISIId)
        super.init()
        // Simple rate limiting, for any rage-shakes emitted we guarantee a spacing between requests.
        e2eDetectedSubject
            .bufferAndSpace(spacingDelay: Self.reportSpacing)
            .sink { [weak self] in
                guard let self = self else { return }
                self.sendRageShake(source: $0)
            }.store(in: &cancellables)
        
        matchingRSRequestSubject
            .bufferAndSpace(spacingDelay: Self.reportSpacing)
            .sink { [weak self] in
                guard let self = self else { return }
                self.sendMatchingRageShake(source: $0)
            }.store(in: &cancellables)
        
        self.enabled = RiotSettings.shared.enableUISIAutoReporting
        RiotSettings.shared.publisher(for: RiotSettings.UserDefaultsKeys.enableUISIAutoReporting)
            .sink {  [weak self] _ in
                guard let self = self else { return }
                self.enabled = RiotSettings.shared.enableUISIAutoReporting
            }
            .store(in: &cancellables)
    }
    
    private lazy var detector: UISIDetector = {
        let detector = UISIDetector()
        detector.delegate = self
        return detector
    }()
    
    var reciprocateToDeviceEventType: String {
        return Self.autoRsRequest
    }
    
    // MARK: - Public
    
    func uisiDetected(source: UISIDetectedMessage) {
        dispatchQueue.async {
            let reportInfo = ReportInfo(roomId: source.roomId, sessionId: source.sessionId)
            let alreadySent = self.alreadyReportedUisi.contains(reportInfo)
            if !alreadySent {
                self.alreadyReportedUisi.insert(reportInfo)
                self.e2eDetectedSubject.send(source)
            }
        }
    }
    
    func add(_ session: MXSession) {
        sessions.append(session)
        detector.enabled = enabled
        session.eventStreamService.add(eventStreamListener: detector)
    }
    
    func remove(_ session: MXSession) {
        if let index = sessions.firstIndex(of: session) {
            sessions.remove(at: index)
        }
        session.eventStreamService.remove(eventStreamListener: detector)
    }
    
    func uisiReciprocateRequest(source: MXEvent) {
        guard source.type == Self.autoRsRequest else { return }
        self.matchingRSRequestSubject.send(source)
    }
    
    // MARK: - Private
    
    private func sendRageShake(source: UISIDetectedMessage) {
        MXLog.debug("[UISIAutoReporter] sendRageShake")
        guard let session = sessions.first else { return }
        let uisiData = UISIAutoReportData(
            eventId: source.eventId,
            roomId: source.roomId,
            senderKey: source.senderKey,
            deviceId: source.senderDeviceId,
            userId: source.senderUserId,
            sessionId: source.sessionId
        ).jsonString ?? ""
        
        self.bugReporter.vc_sendBugReport(
            description: "Auto-reporting decryption error",
            sendLogs: true,
            sendCrashLog: true,
            additionalLabels: [
                "Z-UISI",
                "ios",
                "uisi-recipient"
            ],
            customFields: ["auto_uisi": uisiData],
            success: { reportUrl in
                let contentMap = MXUsersDevicesMap<NSDictionary>()
                let content = [
                    "event_id": source.eventId,
                    "room_id": source.roomId,
                    "session_id": source.sessionId,
                    "device_id": source.senderDeviceId,
                    "user_id": source.senderUserId,
                    "sender_key": source.senderKey,
                    "recipient_rageshake": reportUrl
                ]
                contentMap.setObject(content as NSDictionary, forUser: source.senderUserId, andDevice: source.senderDeviceId)
                session.matrixRestClient.sendDirectToDevice(
                    eventType: Self.autoRsRequest,
                    contentMap: contentMap,
                    txnId: nil
                ) { response in
                    if response.isFailure {
                        MXLog.warning("failed to send auto-uisi to device")
                    }
                }
            },
            failure: { [weak self] error in
                guard let self = self else { return }
                self.dispatchQueue.async {
                    self.alreadyReportedUisi.remove(ReportInfo(roomId: source.roomId, sessionId: source.sessionId))
                }
            })
    }
    
    private func sendMatchingRageShake(source: MXEvent) {
        MXLog.debug("[UISIAutoReporter] sendMatchingRageShake")
        let eventId = source.content["event_id"] as? String
        let roomId = source.content["room_id"] as? String
        let sessionId = source.content["session_id"] as? String
        let deviceId = source.content["device_id"] as? String
        let userId = source.content["user_id"] as? String
        let senderKey = source.content["sender_key"] as? String
        let matchingIssue = source.content["recipient_rageshake"] as? String
        
        var description = "Auto-reporting decryption error (sender)"
        if let matchingIssue = matchingIssue {
            description += "\nRecipient rageshake: \(matchingIssue)"
        }
        
        let uisiData = UISIAutoReportData(
            eventId: eventId,
            roomId: roomId,
            senderKey: senderKey,
            deviceId: deviceId,
            userId: userId,
            sessionId: sessionId
        ).jsonString ?? ""
        
        self.bugReporter.vc_sendBugReport(
            description: description,
            sendLogs: true,
            sendCrashLog: true,
            additionalLabels: [
                "Z-UISI",
                "ios",
                "uisi-sender"
            ],
            customFields: [
                "auto_uisi": uisiData,
                "recipient_rageshake": matchingIssue ?? ""
            ]
        )
    }
    
}
