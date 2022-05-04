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
    // MARK: - Internal Properties
    var roomMember: MXRoomMember?
    var isCurrentUser: Bool = false
    var alpha: CGFloat = 1.0

    // MARK: - Constants
    private enum Constants {
        static let roomMemberKey: String = "roomMember"
        static let isCurrentUserKey: String = "isCurrentUser"
        static let alphaKey: String = "alpha"
        static let pillVerticalOffset: CGFloat = -7.5
    }

    // MARK: - Init
    override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }

    init(withRoomMember roomMember: MXRoomMember, isCurrentUser: Bool) {
        super.init(data: nil, ofType: StringPillsUtils.pillUTType)
        self.roomMember = roomMember
        self.isCurrentUser = isCurrentUser
        let pillSize = PillAttachmentView.size(forRoomMember: roomMember)
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: Constants.pillVerticalOffset), size: pillSize)
    }

    // MARK: - NSCoding
    required init?(coder: NSCoder) {
        guard let roomMember = coder.decodeObject(of: MXRoomMember.self, forKey: Constants.roomMemberKey) else {
            return nil
        }

        super.init(coder: coder)
        self.fileType = StringPillsUtils.pillUTType

        self.roomMember = roomMember
        self.isCurrentUser = coder.decodeBool(forKey: Constants.isCurrentUserKey)
        self.alpha = CGFloat(coder.decodeFloat(forKey: Constants.alphaKey))

        let pillSize = PillAttachmentView.size(forRoomMember: roomMember)
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: -6.5), size: pillSize)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        coder.encode(roomMember, forKey: Constants.roomMemberKey)
        coder.encode(isCurrentUser, forKey: Constants.isCurrentUserKey)
        coder.encode(Float(alpha), forKey: Constants.alphaKey)
    }
}
