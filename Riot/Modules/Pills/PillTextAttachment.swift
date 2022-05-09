// 
// Copyright 2022 New Vector Ltd
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

import UIKit
import MatrixSDK

/// Text attachment for pills display.
@available (iOS 15.0, *)
@objcMembers
class PillTextAttachment: NSTextAttachment {
    // MARK: - Properties
    /// Return `PillTextAttachmentData` contained in the text attachment.
    var data: PillTextAttachmentData? {
        get {
            guard let contents = contents else { return nil }
            return try? Self.serializationService.deserialize(contents)
        }
        set {
            guard let newValue = newValue else {
                contents = nil
                return
            }
            contents = try? Self.serializationService.serialize(newValue)
        }
    }
    private static let serializationService: SerializationServiceType = SerializationService()
    private static let pillVerticalOffset: CGFloat = -7.5

    // MARK: - Init
    override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)

        updateBounds()
    }

    /// Create a Mention Pill text attachment for given room member.
    ///
    /// - Parameters:
    ///   - roomMember: the room member
    ///   - isHighlighted: whether this pill should be highlighted
    convenience init?(withRoomMember roomMember: MXRoomMember, isHighlighted: Bool) {
        let data = PillTextAttachmentData(matrixItemId: roomMember.userId,
                                          displayName: roomMember.displayname,
                                          avatarUrl: roomMember.avatarUrl,
                                          isHighlighted: isHighlighted,
                                          alpha: 1.0)

        guard let encodedData = try? Self.serializationService.serialize(data) else { return nil }
        self.init(data: encodedData, ofType: PillsFormatter.pillUTType)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        updateBounds()
    }
}

// MARK: - Private
@available (iOS 15.0, *)
private extension PillTextAttachment {
    func updateBounds() {
        guard let data = data else { return }
        let pillSize = PillAttachmentViewProvider.size(forDisplayText: data.displayText)
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: Self.pillVerticalOffset), size: pillSize)
    }
}
