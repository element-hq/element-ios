/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

#if canImport(JitsiMeetSDK)
import JitsiMeetSDK

enum JitsiServiceError: Error {
    case widgetContentCreationFailed
    case emptyResponse
    case unknown
}

/// JitsiService enables to abstract and configure Jitsi Meet SDK
@objcMembers
final class JitsiService: NSObject {
    
    static let shared = JitsiService()
    
    private enum Constants {
        static let widgetIdLength = 7
    }
    
    private struct Route {
        static let wellKnown = "/.well-known/element/jitsi"
    }
    
    // MARK: - Properties
    
    var enableCallKit: Bool = true {
        didSet {
            JMCallKitProxy.enabled = enableCallKit
        }
    }

    var serverURL: URL? {
        return self.jitsiMeet.defaultConferenceOptions?.serverURL
    }

    private let jitsiMeet = JitsiMeet.sharedInstance()
    private var httpClient: MXHTTPClient?
    private let serializationService: SerializationServiceType = SerializationService()
    
    private lazy var jwtTokenBuilder: JitsiJWTTokenBuilder = {
        return JitsiJWTTokenBuilder()
    }()
    
    private var httpClients: [String: MXHTTPClient] = [:]
    
    // MARK: - Setup
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public
    
    // MARK: Configuration
    
    func configureDefaultConferenceOptions(with serverURL: URL) {
        self.jitsiMeet.defaultConferenceOptions = JitsiMeetConferenceOptions.fromBuilder({ (builder) in
            builder.serverURL = serverURL
        })
    }
    
    func configureCallKitProvider(localizedName: String, ringtoneName: String?, iconTemplateImageData: Data?) {
        JMCallKitProxy.configureProvider(localizedName: localizedName, ringtoneSound: ringtoneName, iconTemplateImageData: iconTemplateImageData)
    }
    
    // MARK: WellKnown
    
    /// Get Jitsi server Well-Known
    @discardableResult
    func getWellKnown(for jitsiServerURL: URL, completion: @escaping (Result<JitsiWellKnown, Error>) -> Void) -> MXHTTPOperation? {
        guard let httpClient = self.httpClient(for: jitsiServerURL) else {
            completion(.failure(JitsiServiceError.unknown))
            return nil
        }

        return httpClient.request(withMethod: "GET", path: Route.wellKnown, parameters: nil, success: { response in
            guard let response = response else {
                completion(.failure(JitsiServiceError.emptyResponse))
                return
            }

            do {
                let jitsiWellKnown: JitsiWellKnown = try self.serializationService.deserialize(response)
                completion(.success(jitsiWellKnown))
            } catch {
                completion(.failure(error))
            }
        }, failure: { (error) in
            completion(.failure(error ?? JitsiServiceError.unknown))
        })
    }
    
    /// Create Jitsi widget content
    @discardableResult
    func createJitsiWidgetContent(jitsiServerURL: URL, roomID: String, isAudioOnly: Bool, success: @escaping ([String: Any]) -> Void, failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        return self.getWellKnown(for: jitsiServerURL) { (result) in
            switch result {
            case .success(let jitsiWellKnown):
                if let serverDomain = jitsiServerURL.host, let widgetContent = self.createJitsiWidgetContent(serverDomain: serverDomain,
                                                                                                             authenticationType: jitsiWellKnown.authenticationType,
                                                                                                             roomID: roomID,
                                                                                                             isAudioOnly: isAudioOnly) {
                    success(widgetContent)
                } else {
                    failure(JitsiServiceError.widgetContentCreationFailed)
                }
            case .failure(let error):
                NSLog("[JitsiService] Fail to get Jitsi Well Known with error: \(error)")
                failure(error)
            }
        }
    }
    
    /// Check if Jitsi widget requires "openidtoken-jwt" authentication
    func isOpenIdJWTAuthenticationRequired(for widgetData: JitsiWidgetData) -> Bool {
        return widgetData.authenticationType == JitsiAuthenticationType.openIDTokenJWT.identifier
    }
    
    /// Get Jitsi JWT token using user OpenID token
    @discardableResult
    func getOpenIdJWTToken(jitsiServerDomain: String,
                           roomId: String,
                           matrixSession: MXSession,
                           success: @escaping (String) -> Void,
                           failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        
        let myUser: MXUser = matrixSession.myUser
        let userDisplayName: String = myUser.displayname ?? myUser.userId
        let avatarStringURL: String = myUser.avatarUrl ?? ""
        
        return matrixSession.matrixRestClient.openIdToken({ (openIdToken) in
            guard let openIdToken = openIdToken, let openIdAccessToken = openIdToken.accessToken else {
                failure(JitsiServiceError.unknown)
                return
            }
            
            do {
                let jwtToken = try self.jwtTokenBuilder.build(jitsiServerDomain: jitsiServerDomain,
                openIdAccessToken: openIdAccessToken,
                roomId: roomId,
                userAvatarUrl: avatarStringURL,
                userDisplayName: userDisplayName)
                
                success(jwtToken)
            } catch {
                failure(error)
            }
        }, failure: { error in
            failure(error ?? JitsiServiceError.unknown)
        })
    }
    
    // MARK: AppDelegate methods
    
    @discardableResult
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return self.jitsiMeet.application(application, didFinishLaunchingWithOptions: launchOptions ?? [:])
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return self.jitsiMeet.application(application, open: url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return self.jitsiMeet.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    // MARK: - Private
    
    private func httpClient(for jitsiServerURL: URL) -> MXHTTPClient? {
        let httpClient: MXHTTPClient?
        
        let baseStringURL = jitsiServerURL.absoluteString
        
        if let existingHttpClient = self.httpClients[baseStringURL] {
            httpClient = existingHttpClient
        } else if let createdHttpClient = MXHTTPClient(baseURL: baseStringURL, andOnUnrecognizedCertificateBlock: nil) {
            
            httpClient = createdHttpClient
            self.httpClients[baseStringURL] = httpClient
        } else {
            httpClient = nil
        }
        
        return httpClient
    }
    
    private func createJitsiWidgetContent(serverDomain: String,
                                          authenticationType: JitsiAuthenticationType?,
                                          roomID: String,
                                          isAudioOnly: Bool) -> [String: Any]? {
        guard MXTools.isMatrixRoomIdentifier(roomID) else {
            NSLog("[JitsiService] createJitsiWidgetContent the roomID is not valid")
            return nil
        }
        
        // Create a random enough jitsi conference id
        // Note: the jitsi server automatically creates conference when the conference
        // id does not exist yet
        let widgetSessionId = (ProcessInfo.processInfo.globallyUniqueString as NSString).substring(to: Constants.widgetIdLength).lowercased()
                        
        let conferenceID: String
        
        let authenticationTypeString: String?
        
        if let authenticationType = authenticationType, authenticationType == .openIDTokenJWT {
            
            // For compatibility with Jitsi, use base32 without padding.
            // More details here:
            // https://github.com/matrix-org/prosody-mod-auth-matrix-user-verification
            conferenceID = Base32Coder.encodedString(roomID, padding: false)
            authenticationTypeString = authenticationType.identifier
        } else {
            let roomIdComponents = RoomIdComponents(matrixID: roomID)
            let localRoomId = roomIdComponents?.localRoomId ?? ""
            conferenceID = localRoomId + widgetSessionId
            authenticationTypeString = nil
        }
        
        // Build widget url
        // Riot-iOS does not directly use it but extracts params from it (see `[JitsiViewController openWidget:withVideo:]`)
        // This url can be used as is inside a web container (like iframe for Riot-web)
        
        // Build it from the riot-web app
        let appUrlString = BuildSettings.applicationWebAppUrlString
        
        // We mix v1 and v2 param for backward compability
        let v1queryStringParts = [
            "confId=\(conferenceID)",
            "isAudioConf=\(isAudioOnly ? "true" : "false")",
            "displayName=$matrix_display_name",
            "avatarUrl=$matrix_avatar_url",
            "email=$matrix_user_id"
        ]
        
        let v1Params = v1queryStringParts.joined(separator: "&")
                        
        var v2queryStringParts = [
            "conferenceDomain=$domain",
            "conferenceId=$conferenceId",
            "isAudioOnly=$isAudioOnly",
            "displayName=$matrix_display_name",
            "avatarUrl=$matrix_avatar_url",
            "userId=$matrix_user_id"
        ]
        
        if let authenticationTypeString = authenticationTypeString {
            v2queryStringParts.append("auth=\(authenticationTypeString)")
        }
        
        let v2Params = v2queryStringParts.joined(separator: "&")
        
        let widgetStringURL = "\(appUrlString)/widgets/jitsi.html?\(v1Params)#\(v2Params)"
        
        // Build widget data
        // We mix v1 and v2 widget data for backward compability
        let jitsiWidgetData = JitsiWidgetData()
        jitsiWidgetData.domain = serverDomain
        jitsiWidgetData.conferenceId = conferenceID
        jitsiWidgetData.isAudioOnly = isAudioOnly
        jitsiWidgetData.authenticationType = authenticationType?.identifier
        
        let v2WidgetData: [AnyHashable: Any] = jitsiWidgetData.jsonDictionary()
                
        var v1AndV2WidgetData = v2WidgetData
        v1AndV2WidgetData["widgetSessionId"] = widgetSessionId
        
        let widgetContent: [String: Any] = [
            "url": widgetStringURL,
            "type": kWidgetTypeJitsiV1,
            "data": v1AndV2WidgetData
        ]
        
        return widgetContent
    }
}
#endif
