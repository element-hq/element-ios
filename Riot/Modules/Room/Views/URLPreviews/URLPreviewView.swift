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

@objcMembers
class URLPreviewView: UIView, NibLoadable, Themable {
    // MARK: - Constants
    
    private enum Constants { }
    
    // MARK: - Properties
    
    var viewModel: URLPreviewViewModel! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var faviconImageView: UIImageView!
    
    @IBOutlet weak var siteNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: RoomBubbleCellLayout.urlPreviewViewWidth, height: RoomBubbleCellLayout.urlPreviewViewHeight)
    }
    
    // MARK: - Setup
    
    static func instantiate(viewModel: URLPreviewViewModel) -> Self {
        let view = Self.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        
        view.viewModel = viewModel
        viewModel.process(viewAction: .loadData)
        
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        faviconImageView.layer.cornerRadius = 6
        
        siteNameLabel.isUserInteractionEnabled = false
        titleLabel.isUserInteractionEnabled = false
        descriptionLabel.isUserInteractionEnabled = false
        
        #warning("Debugging for previews - to be removed")
        faviconImageView.backgroundColor = .systemBlue.withAlphaComponent(0.7)
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
    }
    
    // MARK: - Private
    private func renderLoading(_ url: URL) {
        imageView.image = nil
        
        siteNameLabel.text = url.host
        titleLabel.text = "Loading..."
        descriptionLabel.text = ""
    }
    
    private func renderLoaded(_ preview: URLPreviewViewData) {
        imageView.image = preview.image
        
        siteNameLabel.text = preview.siteName ?? preview.url.host
        titleLabel.text = preview.title
        descriptionLabel.text = preview.text
    }
    
    private func renderError(_ error: Error) {
        imageView.image = nil
        
        siteNameLabel.text = "Error"
        titleLabel.text = descriptionLabel.text
        descriptionLabel.text = error.localizedDescription
    }
    
    
    // MARK: - Action
    @IBAction private func openURL(_ sender: Any) {
        MXLog.debug("[URLPreviewView] Link was tapped.")
        viewModel.process(viewAction: .openURL)
    }
    
    @IBAction private func close(_ sender: Any) {
        
    }
}


// MARK: URLPreviewViewModelViewDelegate
extension URLPreviewView: URLPreviewViewModelViewDelegate {
    func urlPreviewViewModel(_ viewModel: URLPreviewViewModelType, didUpdateViewState viewState: URLPreviewViewState) {
        DispatchQueue.main.async {
            switch viewState {
            case .loading(let url):
                self.renderLoading(url)
            case .loaded(let preview):
                self.renderLoaded(preview)
            case .error(let error):
                self.renderError(error)
            case .hidden:
                self.frame.size.height = 0
            }
        }
    }
}
