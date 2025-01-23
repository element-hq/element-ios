// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Provider for mention Pills attachment view.
@available(iOS 15.0, *)
@objc class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    // MARK: - Properties
    static let pillAttachmentViewSizes = PillAttachmentView.Sizes(verticalMargin: 2.0,
                                                                  horizontalMargin: 6.0,
                                                                  avatarLeading: 2.0,
                                                                  avatarSideLength: 16.0,
                                                                  itemSpacing: 4)
    private weak var messageTextView: UITextView?
    private var pillViewFlusher: PillViewFlusher? {
        messageTextView as? PillViewFlusher
    }

    // MARK: - Override
    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        // Keep a reference to the parent text view for size adjustments and pills flushing.
        messageTextView = parentView?.superview as? UITextView
    }

    override func loadView() {
        super.loadView()

        guard let textAttachment = self.textAttachment as? PillTextAttachment else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment is missing or not of expected class")
            return
        }

        guard var pillData = textAttachment.data else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment misses pill data")
            return
        }
        
        if let messageTextView {
            pillData.maxWidth = messageTextView.bounds.width - 8
        }
        
        let mainSession = AppDelegate.theDelegate().mxSessions.first as? MXSession

        let pillView = PillAttachmentView(frame: CGRect(origin: .zero, size: textAttachment.size(forFont: pillData.font)),
                                          sizes: Self.pillAttachmentViewSizes,
                                          theme: ThemeService.shared().theme,
                                          mediaManager: mainSession?.mediaManager,
                                          andPillData: pillData)
        view = pillView

        if let pillViewFlusher {
            pillViewFlusher.registerPillView(pillView)
        } else {
            MXLog.failure("[PillAttachmentViewProvider]: no handler found, pill will not be flushed properly")
        }
    }
}
