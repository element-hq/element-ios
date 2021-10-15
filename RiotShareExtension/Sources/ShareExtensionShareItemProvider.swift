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
import MobileCoreServices

let UTTypeText = kUTTypeText as String
let UTTypeURL = kUTTypeURL as String
let UTTypeFileUrl = kUTTypeFileURL as String
let UTTypeImage = kUTTypeImage as String
let UTTypeVideo = kUTTypeVideo as String
let UTTypeMovie = kUTTypeMovie as String

private class ShareExtensionItem: ShareItemProtocol {
    let itemProvider: NSItemProvider
    
    var loaded = false
    
    init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
    }
    
    var type: ShareItemType {
        if itemProvider.hasItemConformingToTypeIdentifier(UTTypeText) {
            return .text
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTTypeURL) {
            return .URL
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTTypeFileUrl) {
            return .fileURL
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTTypeImage) {
            return .image
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTTypeVideo) {
            return .video
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTTypeMovie) {
            return .movie
        }
        
        return .unknown
    }
}

@objcMembers
class ShareExtensionShareItemProvider: NSObject, ShareItemProviderProtocol	 {
    
    public let items: [ShareItemProtocol]
    
    public init(extensionContext: NSExtensionContext) {
        
        var items: [ShareItemProtocol] = []
        for case let extensionItem as NSExtensionItem in extensionContext.inputItems {
            guard let attachments = extensionItem.attachments else {
                continue;
            }
            
            for itemProvider in attachments {
                items.append(ShareExtensionItem(itemProvider: itemProvider))
            }
        }
        self.items = items
    }
    
    func areAllItemsLoaded() -> Bool {
        for case let item as ShareExtensionItem in self.items {
            if !item.loaded {
                return false
            }
        }
        
        return true
    }
    
    func areAllItemsImages() -> Bool {
        for case let item as ShareExtensionItem in self.items {
            if item.type != .image {
                return false
            }
        }
        
        return true
    }
    
    func loadItem(_ item: ShareItemProtocol, completion: @escaping (Any?, Error?) -> Void) {
        guard let shareExtensionItem = item as? ShareExtensionItem else {
            fatalError("[ShareExtensionShareItemProvider] Unexpected item type.")
        }
        
        let typeIdentifier = typeIdentifierForType(item.type)
        
        shareExtensionItem.loaded = false
        shareExtensionItem.itemProvider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { result, error in
            if error == nil {
                shareExtensionItem.loaded = true
            }
            
            completion(result, error)
        }
    }
    
    // MARK: - Private
    
    private func typeIdentifierForType(_ type: ShareItemType) -> String {
        switch type {
        case .text:
            return UTTypeText
        case .URL:
            return UTTypeURL
        case .fileURL:
            return UTTypeFileUrl
        case .image:
            return UTTypeImage
        case .video:
            return UTTypeVideo
        case .movie:
            return UTTypeMovie
        case .voiceMessage:
            return UTTypeFileUrl
        default:
            return ""
        }
    }
}
