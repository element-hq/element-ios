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

import Foundation
import MatrixSDK

@objcMembers
class URLPreviewViewModel: NSObject, URLPreviewViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    /// The original (un-sanitized) URL to be previewed.
    private let url: URL
    private let session: MXSession
    
    private var currentOperation: MXHTTPOperation?
    private var urlPreview: MXURLPreview?
    
    // MARK: Public

    weak var viewDelegate: URLPreviewViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(url: URL, session: MXSession) {
        self.url = url
        self.session = session
    }
    
    deinit {
        cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: URLPreviewViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .openURL:
            openURL()
        case .close:
            cancelOperations()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        update(viewState: .loading(url))
        
        AppDelegate.theDelegate().previewManager.preview(for: url) { [weak self] preview in
            guard let self = self else { return }
            
            self.update(viewState: .loaded(preview))
        } failure: { error in
            #warning("REALLY?!")
            if let error = error {
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func openURL() {
        // Open the original (un-sanitized) URL stored in the view model.
        UIApplication.shared.open(url)
    }
    
    private func update(viewState: URLPreviewViewState) {
        viewDelegate?.urlPreviewViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        currentOperation?.cancel()
    }
}
