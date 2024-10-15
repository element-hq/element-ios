/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

enum EmojiServiceError: Error {
    case emojiJSONFileNotFound
}

/// Emoji service powered by Emoji Mart data (https://github.com/missive/emoji-mart/)
final class EmojiMartService: EmojiServiceType {
    
    // MARK: - Constants
    
    /// Emoji data coming from https://github.com/missive/emoji-mart/blob/master/data/apple.json
    private static let jsonFilename = "apple_emojis_data"
    
    // MARK: - Properties
    
    private let serializationService: SerializationServiceType = SerializationService()
    private let serviceQueue = DispatchQueue(label: "\(type(of: EmojiMartService.self))")
    
    // MARK: - Public
    
    func getEmojiCategories(completion: @escaping (MXResponse<[EmojiCategory]>) -> Void) {
        self.serviceQueue.async {
            do {
                let emojiJSONData = try self.getEmojisJSONData()
                let emojiJSONStore: EmojiMartStore = try self.serializationService.deserialize(emojiJSONData)
                let emojiCategories = self.emojiCategories(from: emojiJSONStore)
                DispatchQueue.main.async {
                    completion(MXResponse.success(emojiCategories))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(MXResponse.failure(error))
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func getEmojisJSONData() throws -> Data {
        guard let jsonDataURL = Bundle.main.url(forResource: EmojiMartService.jsonFilename, withExtension: "json") else {
                throw EmojiServiceError.emojiJSONFileNotFound
        }
        let jsonData = try Data(contentsOf: jsonDataURL)
        return jsonData
    }
    
    private func emojiCategories(from emojiJSONStore: EmojiMartStore) -> [EmojiCategory] {
        let allEmojiItems = emojiJSONStore.emojis
        
        return emojiJSONStore.categories.map { (jsonCategory) -> EmojiCategory in
            let emojiItems = jsonCategory.emojiShortNames.compactMap({ (shortName) -> EmojiItem? in
                return allEmojiItems.first(where: { $0.shortName == shortName })
            })
            return EmojiCategory(identifier: jsonCategory.identifier, emojis: emojiItems)
        }
    }

}
