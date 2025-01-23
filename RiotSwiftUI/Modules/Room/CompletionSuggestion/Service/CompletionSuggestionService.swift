//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import WysiwygComposer

struct RoomMembersProviderMember {
    var userId: String
    var displayName: String
    var avatarUrl: String
}

struct CommandsProviderCommand {
    let name: String
    let parametersFormat: String
    let description: String
    let requiresAdminPowerLevel: Bool
}

class CompletionSuggestionUserID: NSObject {
    /// A special case added for suggesting `@room` mentions.
    @objc static let room = "@room"
}

protocol RoomMembersProviderProtocol {
    var canMentionRoom: Bool { get }
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void)
}

protocol CommandsProviderProtocol {
    var isRoomAdmin: Bool { get }
    func fetchCommands(_ commands: @escaping ([CommandsProviderCommand]) -> Void)
}

struct CompletionSuggestionServiceUserItem: CompletionSuggestionUserItemProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
}

struct CompletionSuggestionServiceCommandItem: CompletionSuggestionCommandItemProtocol {
    let name: String
    let parametersFormat: String
    let description: String
}

class CompletionSuggestionService: CompletionSuggestionServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomMemberProvider: RoomMembersProviderProtocol
    private let commandProvider: CommandsProviderProtocol
    
    private var suggestionItems: [CompletionSuggestionItem] = []
    private let currentTextTriggerSubject = CurrentValueSubject<TextTrigger?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    
    var items = CurrentValueSubject<[CompletionSuggestionItem], Never>([])
    
    var currentTextTrigger: String? {
        currentTextTriggerSubject.value?.asString()
    }
    
    // MARK: - Setup
    
    init(roomMemberProvider: RoomMembersProviderProtocol,
         commandProvider: CommandsProviderProtocol,
         shouldDebounce: Bool = true) {
        self.roomMemberProvider = roomMemberProvider
        self.commandProvider = commandProvider
        
        if shouldDebounce {
            currentTextTriggerSubject
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] in self?.fetchAndFilterSuggestionsForTextTrigger($0) }
                .store(in: &cancellables)
        } else {
            currentTextTriggerSubject
                .sink { [weak self] in self?.fetchAndFilterSuggestionsForTextTrigger($0) }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - CompletionSuggestionServiceProtocol
    
    func processTextMessage(_ textMessage: String?) {
        guard let textMessage = textMessage,
              let textTrigger = textMessage.currentTextTrigger
        else {
            items.send([])
            currentTextTriggerSubject.send(nil)
            return
        }
        
        currentTextTriggerSubject.send(textTrigger)
    }

    func processSuggestionPattern(_ suggestionPattern: SuggestionPattern?) {
        guard let suggestionPattern else {
            items.send([])
            currentTextTriggerSubject.send(nil)
            return
        }

        switch suggestionPattern.key {
        case .at:
            currentTextTriggerSubject.send(TextTrigger(key: .at, text: suggestionPattern.text))
        case .hash:
            // No room suggestion support yet
            items.send([])
            currentTextTriggerSubject.send(nil)
        case .slash:
            currentTextTriggerSubject.send(TextTrigger(key: .slash, text: suggestionPattern.text))
        }
    }
    
    // MARK: - Private
    
    private func fetchAndFilterSuggestionsForTextTrigger(_ textTrigger: TextTrigger?) {
        guard let textTrigger else { return }

        switch textTrigger.key {
        case .at:
            roomMemberProvider.fetchMembers { [weak self] members in
                guard let self = self else {
                    return
                }

                self.suggestionItems = members.withRoom(self.roomMemberProvider.canMentionRoom).map { member in
                    CompletionSuggestionItem.user(value: CompletionSuggestionServiceUserItem(userId: member.userId, displayName: member.displayName, avatarUrl: member.avatarUrl))
                }

                self.items.send(self.suggestionItems.filter { item in
                    guard case let .user(completionSuggestionUserItem) = item else { return false }

                    let containedInUsername = completionSuggestionUserItem.userId.lowercased().contains(textTrigger.text.lowercased())
                    let containedInDisplayName = (completionSuggestionUserItem.displayName ?? "").lowercased().contains(textTrigger.text.lowercased())

                    return (containedInUsername || containedInDisplayName)
                })
            }
        case .slash:
            commandProvider.fetchCommands { [weak self] commands in
                guard let self else { return }

                self.suggestionItems = commands.filtered(isRoomAdmin: self.commandProvider.isRoomAdmin).map { command in
                    CompletionSuggestionItem.command(value: CompletionSuggestionServiceCommandItem(
                        name: command.name,
                        parametersFormat: command.parametersFormat,
                        description: command.description
                    ))
                }

                if textTrigger.text.isEmpty {
                    // A single `/` will display all available commands.
                    self.items.send(self.suggestionItems)
                } else {
                    self.items.send(self.suggestionItems.filter { item in
                        guard case let .command(commandSuggestion) = item else { return false }

                        return commandSuggestion.name.lowercased().contains(textTrigger.text.lowercased())
                    })
                }
            }
        }
    }
}

extension Array where Element == RoomMembersProviderMember {
    /// Returns the array with an additional member that represents an `@room` mention.
    func withRoom(_ canMentionRoom: Bool) -> Self {
        guard canMentionRoom else { return self }
        return self + [RoomMembersProviderMember(userId: CompletionSuggestionUserID.room, displayName: "Everyone", avatarUrl: "")]
    }
}

extension Array where Element == CommandsProviderCommand {
    func filtered(isRoomAdmin: Bool) -> Self {
        guard !isRoomAdmin else { return self }
        return filter { !$0.requiresAdminPowerLevel }
    }
}

private enum SuggestionKey: Character {
    case at = "@"
    case slash = "/"
}

private struct TextTrigger: Equatable {
    let key: SuggestionKey
    let text: String

    func asString() -> String {
        String(key.rawValue) + text
    }
}

private extension String {
    // Returns current completion suggestion for a text message, if any.
    var currentTextTrigger: TextTrigger? {
        let components = components(separatedBy: .whitespaces)
        guard var lastComponent = components.last,
              lastComponent.count > 0,
              let suggestionKey = SuggestionKey(rawValue: lastComponent.removeFirst()),
              // If a second character exists and is the same as the key it shouldn't trigger.
              lastComponent.first != suggestionKey.rawValue,
              // Slash commands should be displayed only if there is a single component
              !(suggestionKey == .slash && components.count > 1)
        else { return nil }

        return TextTrigger(key: suggestionKey, text: lastComponent)
    }
}
