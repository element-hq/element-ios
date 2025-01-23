//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import WebKit

struct AuthenticationRecaptchaWebView: UIViewRepresentable {
    // MARK: - Properties
    
    // MARK: Public
    
    /// The `siteKey` string to pass to the ReCaptcha widget.
    let siteKey: String
    /// The homeserver's URL, used so ReCaptcha can validate where the request is coming from.
    let homeserverURL: URL
    
    /// A binding to boolean that controls whether or not a loading spinner should be shown.
    @Binding var isLoading: Bool
    
    /// The completion called when the ReCaptcha was successful. The response string
    /// is passed into the closure as the only argument.
    let completion: (String) -> Void
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Setup
    
    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "recaptcha")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        #if DEBUG
        // Use a randomised user agent to encourage the ReCaptcha to show a challenge.
        webView.customUserAgent = "Show Me The Traffic Lights \(Float.random(in: 1...100))"
        #endif
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let recaptchaTheme: Coordinator.ReCaptchaTheme = theme.isDark ? .dark : .light
        webView.loadHTMLString(context.coordinator.htmlString(with: siteKey, using: recaptchaTheme), baseURL: homeserverURL)
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(isLoading: $isLoading)
        coordinator.completion = completion
        return coordinator
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        /// The theme used to render the ReCaptcha
        enum ReCaptchaTheme: String { case light, dark }
        
        /// A binding to boolean that controls whether or not a loading spinner should be shown.
        @Binding var isLoading: Bool
        
        /// The completion called when the ReCaptcha was successful. The response string
        /// is passed into the closure as the only argument.
        var completion: ((String) -> Void)?
        
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        /// Generates the HTML page to show for the given `siteKey` and `theme`.
        func htmlString(with siteKey: String, using theme: ReCaptchaTheme) -> String {
            """
            <html>
            <head>
            <meta name='viewport' content='initial-scale=1.0, user-scalable=no' />
            <style>@media (prefers-color-scheme: dark) { body { background-color: #15191E; } }</style>
            <script type="text/javascript">
            var verifyCallback = function(response) {
                window.webkit.messageHandlers.recaptcha.postMessage(response);
            };
            var onloadCallback = function() {
                grecaptcha.render('recaptcha_widget', {
                    'sitekey' : '\(siteKey)',
                    'callback': verifyCallback,
                    'theme': '\(theme.rawValue)'
                });
            };
            </script>
            </head>
            <body style="margin: 16px;">
                <div id="recaptcha_widget"></div>
                <script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit" async defer>
                </script>
            </body>
            </html>
            """
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let response = message.body as? String else { return }
            completion?(response)
        }
    }
}
