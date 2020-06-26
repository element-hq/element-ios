/*
 Copyright 2020 New Vector Ltd
 
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

private var _notifySettingForNotifications: RoomNotificationSetting?
private var _soundSettingForNotifications: RoomNotificationSetting?
private var _notifyOnRoomMentions: Bool?
private var _showNumberOfMessages: Bool?

extension MXRoom {
    
    var notifySettingForNotifications: RoomNotificationSetting {
        return _notifySettingForNotifications ?? .mentionsKeywords
    }
    
    var soundSettingForNotifications: RoomNotificationSetting {
        return _soundSettingForNotifications ?? .dmsMentionsKeywords
    }
    
    var notifyOnRoomMentions: Bool {
        return _notifyOnRoomMentions ?? true
    }
    
    var showNumberOfMessages: Bool {
        return _showNumberOfMessages ?? false
    }
    
    func updateNotifySetting(to newSetting: RoomNotificationSetting, completion: @escaping (_ response: MXResponse<Void>) -> Void) {
        let isSuccess = Bool.random()
        if isSuccess {
            _notifySettingForNotifications = newSetting
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if isSuccess {
                completion(MXResponse<Void>.success(Void()))
            } else {
                completion(MXResponse<Void>.failure(NSError(domain: "Some domain", code: 1002, userInfo: nil)))
            }
        }
    }
    
    func updateSoundSetting(to newSetting: RoomNotificationSetting, completion: @escaping (_ response: MXResponse<Void>) -> Void) {
        let isSuccess = Bool.random()
        if isSuccess {
            _soundSettingForNotifications = newSetting
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if isSuccess {
                completion(MXResponse<Void>.success(Void()))
            } else {
                completion(MXResponse<Void>.failure(NSError(domain: "Some domain", code: 1002, userInfo: nil)))
            }
        }
    }
    
    func updateNotifyOnRoomMentionsSetting(to newSetting: Bool, completion: @escaping (_ response: MXResponse<Void>) -> Void) {
        let isSuccess = Bool.random()
        if isSuccess {
            _notifyOnRoomMentions = newSetting
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if isSuccess {
                completion(MXResponse<Void>.success(Void()))
            } else {
                completion(MXResponse<Void>.failure(NSError(domain: "Some domain", code: 1002, userInfo: nil)))
            }
        }
    }
    
    func updateShowNumberOfMessagesSetting(to newSetting: Bool, completion: @escaping (_ response: MXResponse<Void>) -> Void) {
        let isSuccess = Bool.random()
        if isSuccess {
            _showNumberOfMessages = newSetting
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if isSuccess {
                completion(MXResponse<Void>.success(Void()))
            } else {
                completion(MXResponse<Void>.failure(NSError(domain: "Some domain", code: 1002, userInfo: nil)))
            }
        }
    }
    
}
