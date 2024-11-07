/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
