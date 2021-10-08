/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objc protocol GDPRConsentViewControllerDelegate: AnyObject {
    func gdprConsentViewControllerDidConsentToGDPRWithSuccess(_ gdprConsentViewController: GDPRConsentViewController)
}

/// GPDR consent screen.
final public class GDPRConsentViewController: WebViewViewController {
    
    // MARK: - Constants
    
    private static let consentSuccessURLPath = "/_matrix/consent"
    
    // MARK: - Properties        
    
    @objc weak var delegate: GDPRConsentViewControllerDelegate?
    
    // MARK: - View life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = VectorL10n.settingsTermConditions
    }
    
    // MARK: - Superclass Overrides
    
    override public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        
        // When navigation finish on path `consentSuccessURLPath` with no query, it means that user consent to GDPR
        if let url = webView.url, url.path == GDPRConsentViewController.consentSuccessURLPath, url.query == nil {
            MXLog.debug("[GDPRConsentViewController] User consent to GDPR")
            self.delegate?.gdprConsentViewControllerDidConsentToGDPRWithSuccess(self)
        }
    }
}
