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

/// Provider for mention Pills attachment view.
@available(iOS 15.0, *)
@objc class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        super.loadView()

        guard let textAttachment = self.textAttachment as? PillTextAttachment else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment is missing or not of expected class")
            return
        }

        guard let pillData = textAttachment.data else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment misses room member data")
            return
        }

        view = PillAttachmentView(withPillData: pillData)
        view?.alpha = pillData.alpha
    }
}
