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

private class SimpleShareItem: ShareItemProtocol {
    let attachment: MXKAttachment?
    let textMessage: String?
    
    init(withAttachment attachment: MXKAttachment) {
        self.attachment = attachment
        self.textMessage = nil
    }
    
    init(withTextMessage textMessage: String) {
        self.attachment = nil
        self.textMessage = textMessage
    }
    
    var type: ShareItemType {
        guard textMessage == nil else {
            return .text
        }
        
        guard let attachment = attachment else {
            return .unknown
        }
        
        if attachment.type == MXKAttachmentTypeImage {
            return .image
        } else if attachment.type == MXKAttachmentTypeVideo {
            return .video
        } else if attachment.type == MXKAttachmentTypeFile {
            return .fileURL
        } else if attachment.type == MXKAttachmentTypeVoiceMessage {
            return .voiceMessage
        } else {
            return .unknown
        }
    }
}

@objc class SimpleShareItemProvider: NSObject, ShareItemProviderProtocol {
    
    private let attachment: MXKAttachment?
    private let textMessage: String?
    
    let items: [ShareItemProtocol]
    
    private override init() {
        attachment = nil
        textMessage = nil
        self.items = []
    }
    
    @objc public init(withAttachment attachment: MXKAttachment) {
        self.attachment = attachment
        self.items = [SimpleShareItem(withAttachment: attachment)];
        self.textMessage = nil
    }
    
    @objc public init(withTextMessage textMessage: String) {
        self.textMessage = textMessage
        self.items = [SimpleShareItem(withTextMessage: textMessage)];
        self.attachment = nil
    }
    
    func loadItem(_ item: ShareItemProtocol, completion: @escaping (Any?, Error?) -> Void) {
        if let textMessage = self.textMessage {
            completion(textMessage, nil)
            return
        }
        
        guard let attachment = attachment else {
            fatalError("[SimpleShareItemProvider] Invalid item provider state.")
        }
        
        attachment.prepareShare({ url in
            DispatchQueue.main.async {
                completion(url, nil)
            }
        }, failure: { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        })
    }
    
    func areAllItemsLoaded() -> Bool {
        return true
    }
    
    func areAllItemsImages() -> Bool {
        return (attachment != nil && attachment?.type == MXKAttachmentTypeImage)
    }
}
