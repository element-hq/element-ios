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
        let webView = WKWebView()
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
    
    class Coordinator: NSObject, WKNavigationDelegate {
        /// The theme used to render the ReCaptcha
        enum ReCaptchaTheme: String { case light, dark }
        
        /// A binding to boolean that controls whether or not a loading spinner should be shown.
        @Binding var isLoading: Bool
        
        /// The completion called when the ReCaptcha was successful. The response string
        /// is passed into the closure as the only argument.
        var completion: ((String) -> Void)?
        
        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }
        
        /// Generates the HTML page to show for the given `siteKey` and `theme`.
        func htmlString(with siteKey: String, using theme: ReCaptchaTheme) -> String {
            """
            <html>
            <head>
            <meta name='viewport' content='initial-scale=1.0' />
            <style>@media (prefers-color-scheme: dark) { body { background-color: #15191E; } }</style>
            <script type="text/javascript">
            var verifyCallback = function(response) {
                /* Generic method to make a bridge between JS and the WKWebView*/
                var iframe = document.createElement('iframe');
                iframe.setAttribute('src', 'js:' + JSON.stringify({'action': 'verifyCallback', 'response': response}));
                
                document.documentElement.appendChild(iframe);
                iframe.parentNode.removeChild(iframe);
                iframe = null;
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
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard
                let url = navigationAction.request.url,
                // Listen only to scheme of the JS-WKWebView bridge
                navigationAction.request.url?.scheme == "js"
            else { return .allow }
            
            guard
                let jsonString = url.path.removingPercentEncoding,
                let jsonData = jsonString.data(using: .utf8),
                let parameters = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: String],
                parameters["action"] == "verifyCallback",
                let response = parameters["response"]
            else { return .cancel }
            
            completion?(response)
            
            return .cancel
        }
    }
}

