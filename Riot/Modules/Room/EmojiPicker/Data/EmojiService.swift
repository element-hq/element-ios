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

enum EmojiServiceError: Error {
    case emojiJSONFileNotFound
}

final class EmojiService: EmojiServiceType {
    
    // MARK: - Constants
    
    private static let jsonFilename = "apple_emojis_data"
    
    // MARK: - Properties
    
    private let serializationService: SerializationServiceType = SerializationService()
    private let serviceQueue = DispatchQueue(label: "\(type(of: EmojiService.self))")
    
    // MARK: - Public
    
    func getEmojiCategories(completion: @escaping (MXResponse<[EmojiCategory]>) -> Void) {
        self.serviceQueue.async {
            do {
                let emojiJSONData = try self.getEmojisJSONData()
                let emojiJSONStore: EmojiJSONStore = try self.serializationService.deserialize(emojiJSONData)
                let emojiCategories = self.emojiCategories(from: emojiJSONStore)
                completion(MXResponse.success(emojiCategories))
            } catch {
                completion(MXResponse.failure(error))
            }
        }
    }
    
    // MARK: - Private
    
    private func getEmojisJSONData() throws -> Data {
        guard let jsonDataURL = Bundle.main.url(forResource: EmojiService.jsonFilename, withExtension: "json") else {
                throw EmojiServiceError.emojiJSONFileNotFound
        }
        let jsonData = try Data(contentsOf: jsonDataURL)
        return jsonData
    }
    
    private func emojiCategories(from emojiJSONStore: EmojiJSONStore) -> [EmojiCategory] {
        let allEmojiItems = emojiJSONStore.emojis
        
        return emojiJSONStore.categories.map { (jsonCategory) -> EmojiCategory in
            let emojiItems = jsonCategory.emojiIdentifiers.compactMap({ (emojiIdentifier) -> EmojiItem? in
                return allEmojiItems.first(where: { $0.identifier == emojiIdentifier })
            })
            return EmojiCategory(identifier: jsonCategory.identifier, emojis: emojiItems)
        }
    }

}
