import Foundation

struct AnalyticsEvent {
    struct Error {
        let domain: ErrorDomain
        let name: ErrorName
        let context: String?
    }
    
    enum ErrorDomain: String {
        case E2EE
        case VOIP
    }
    
    enum ErrorName: String {
        case UnknownError
        case OlmIndexError
        case OlmKeysNotSentError
        case OlmUnspecifiedError
        case VoipUserHangup
        case VoipIceFailed
        case VoipInviteTimeout
        case VoipIceTimeout
        case VoipUserMediaFailed
    }
    
    struct CallStarted {
        let placed: Bool
        let isVideo: Bool
        let numParticipants: Int
    }
    
    struct CallEnded {
        let placed: Bool
        let isVideo: Bool
        let durationMs: Int
        let numParticipants: Int
    }
    
    struct CallError {
        let placed: Bool
        let isVideo: Bool
        let numParticipants: Int
    }
}
