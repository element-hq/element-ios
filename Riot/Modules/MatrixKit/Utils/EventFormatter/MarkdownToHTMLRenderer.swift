/*
Copyright 2020 The Matrix.org Foundation C.I.C

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
import Down
import libcmark

@objc public protocol MarkdownToHTMLRendererProtocol: NSObjectProtocol {
    func renderToHTML(markdown: String) -> String?
}

@objcMembers
public class MarkdownToHTMLRenderer: NSObject {
    
    fileprivate var options: DownOptions = []
    
    //  Do not expose an initializer with options, because `DownOptions` is not ObjC compatible.
    public override init() {
        super.init()
    }
}

extension MarkdownToHTMLRenderer: MarkdownToHTMLRendererProtocol {
    
    public func renderToHTML(markdown: String) -> String? {
        return try? Down(markdownString: markdown).toHTML(options)
    }
    
}

@objcMembers
public class MarkdownToHTMLRendererHardBreaks: MarkdownToHTMLRenderer {
    
    public override init() {
        super.init()
        options = .hardBreaks
    }
    
}
