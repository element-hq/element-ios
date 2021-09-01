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

import UIKit
import Reusable

@objc
protocol URLPreviewViewDelegate: AnyObject {
    func didOpenURLFromPreviewView(_ previewView: URLPreviewView, for eventID: String, in roomID: String)
    func didCloseURLPreviewView(_ previewView: URLPreviewView, for eventID: String, in roomID: String)
}

@objcMembers
class URLPreviewView: UIView, NibLoadable, Themable {
    // MARK: - Constants
    
    private static let sizingView = URLPreviewView.instantiate()
    
    private enum Constants {
        // URL Previews
        
        static let maxHeight: CGFloat = 247.0
        static let width: CGFloat = 267.0
    }
    
    // MARK: - Properties
    
    var preview: URLPreviewData? {
        didSet {
            guard let preview = preview else { return }
            renderLoaded(preview)
        }
    }
    
    weak var delegate: URLPreviewViewDelegate?
    
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var siteNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    /// The constraint that pins the top of the text container to the top of the view.
    @IBOutlet weak var textContainerViewConstraint: NSLayoutConstraint!
    /// The constraint that pins the top of the text container to the bottom of the image container.
    @IBOutlet weak var textContainerImageConstraint: NSLayoutConstraint!
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: Constants.width, height: Constants.maxHeight)
    }
    
    // MARK: - Setup
    
    static func instantiate() -> Self {
        let view = Self.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        
        siteNameLabel.isUserInteractionEnabled = false
        titleLabel.isUserInteractionEnabled = false
        descriptionLabel.isUserInteractionEnabled = false
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.navigation
        
        siteNameLabel.textColor = theme.colors.secondaryContent
        siteNameLabel.font = theme.fonts.caption2SB
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.calloutSB
        
        descriptionLabel.textColor = theme.colors.secondaryContent
        descriptionLabel.font = theme.fonts.caption1
        
        let closeButtonAsset = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.urlPreviewCloseDark : Asset.Images.urlPreviewClose
        closeButton.setImage(closeButtonAsset.image, for: .normal)
    }
    
    static func contentViewHeight(for preview: URLPreviewData) -> CGFloat {
        sizingView.renderLoaded(preview)
        
        return sizingView.systemLayoutSizeFitting(sizingView.intrinsicContentSize).height
    }
    
    // MARK: - Private
    #warning("Check whether we should show a loading state.")
    private func renderLoading(_ url: URL) {
        imageView.image = nil
        
        siteNameLabel.text = url.host
        titleLabel.text = "Loading..."
        descriptionLabel.text = ""
    }
    
    private func renderLoaded(_ preview: URLPreviewData) {
        if let image = preview.image {
            imageView.image = image
            showImageContainer()
        } else {
            imageView.image = nil
            hideImageContainer()
        }
        
        siteNameLabel.text = preview.siteName ?? preview.url.host
        titleLabel.text = preview.title
        descriptionLabel.text = preview.text
    }
    
    private func showImageContainer() {
        // When the image container has a superview it is already visible
        guard imageContainer.superview == nil else { return }
        
        textContainerViewConstraint.isActive = false
        addSubview(imageContainer)
        textContainerImageConstraint.isActive = true
        
        // Ensure the close button remains visible
        bringSubviewToFront(closeButton)
    }
    
    private func hideImageContainer() {
        textContainerImageConstraint.isActive = false
        imageContainer.removeFromSuperview()
        textContainerViewConstraint.isActive = true
    }
    
    // MARK: - Action
    @IBAction private func openURL(_ sender: Any) {
        MXLog.debug("[URLPreviewView] Link was tapped.")
        guard let preview = preview else { return }
        
        // Ask the delegate to open the URL for the event, as the bubble component
        // has the original un-sanitized URL that needs to be opened.
        delegate?.didOpenURLFromPreviewView(self, for: preview.eventID, in: preview.roomID)
    }
    
    @IBAction private func close(_ sender: Any) {
        guard let preview = preview else { return }
        delegate?.didCloseURLPreviewView(self, for: preview.eventID, in: preview.roomID)
    }
}
