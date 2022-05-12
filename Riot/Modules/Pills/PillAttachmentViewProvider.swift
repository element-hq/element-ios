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
    private static let pillAttachmentViewSizes = PillAttachmentView.Sizes(verticalMargin: 2.0,
                                                                          horizontalMargin: 4.0,
                                                                          avatarSideLength: 16.0)

    override func loadView() {
        super.loadView()

        guard let textAttachment = self.textAttachment as? PillTextAttachment else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment is missing or not of expected class")
            return
        }

        guard let pillData = textAttachment.data else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment misses pill data")
            return
        }

        let mainSession = AppDelegate.theDelegate().mxSessions.first as? MXSession

        view = PillAttachmentView(frame: CGRect(origin: .zero, size: Self.size(forDisplayText: pillData.displayText,
                                                                               andFont: pillData.font)),
                                  sizes: Self.pillAttachmentViewSizes,
                                  theme: ThemeService.shared().theme,
                                  mediaManager: mainSession?.mediaManager,
                                  andPillData: pillData)
        view?.alpha = pillData.alpha
    }
}

@available(iOS 15.0, *)
extension PillAttachmentViewProvider {
    /// Computes size required to display a pill for given display text.
    ///
    /// - Parameters:
    ///   - displayText: display text for the pill
    ///   - font: the text font
    /// - Returns: required size for pill
    static func size(forDisplayText displayText: String, andFont font: UIFont) -> CGSize {
        let label = UILabel(frame: .zero)
        label.text = displayText
        label.font = font
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: pillAttachmentViewSizes.pillBackgroundHeight))

        return CGSize(width: labelSize.width + pillAttachmentViewSizes.totalWidthWithoutLabel,
                      height: pillAttachmentViewSizes.pillHeight)
    }
}
