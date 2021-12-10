//
// Copyright 2020 The Matrix.org Foundation C.I.C
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

import DTCoreText

public extension DTHTMLElement {
    typealias ImageHandler = (_ sourceURL: String, _ width: CGFloat, _ height: CGFloat) -> URL?
    
    /// Sanitize the element using the given parameters.
    /// - Parameters:
    ///   - allowedHTMLTags: An array of tags that are allowed. All other tags will be removed.
    ///   - font: The default font to use when resetting the content of any unsupported tags.
    ///   - imageHandler: An optional image handler to be run on `img` tags (if allowed) to update the `src` attribute.
    @objc func sanitize(with allowedHTMLTags: [String], bodyFont font: UIFont, imageHandler: ImageHandler?) {
        if let name = name, !allowedHTMLTags.contains(name) {
            
            // This is an unsupported tag.
            // Remove any attachments to fix rendering.
            textAttachment = nil
            
            // If the element has plain text content show that,
            // otherwise prevent the tag from displaying.
            if let stringContent = attributedString()?.string,
               !stringContent.isEmpty,
               let element = DTTextHTMLElement(name: nil, attributes: nil) {
                element.setText(stringContent)
                removeAllChildNodes()
                addChildNode(element)
                
                if let parent = parent() {
                    element.inheritAttributes(from: parent)
                } else {
                    fontDescriptor = DTCoreTextFontDescriptor()
                    fontDescriptor.fontFamily = font.familyName
                    fontDescriptor.fontName = font.fontName
                    fontDescriptor.pointSize = font.pointSize
                    paragraphStyle = DTCoreTextParagraphStyle.default()
                    
                    element.inheritAttributes(from: self)
                }
                element.interpretAttributes()
                
            } else if let parent = parent() {
                parent.removeChildNode(self)
            } else {
                didOutput = true
            }
            
        } else {
            // Process images with the handler when self is an image tag.
            if name == "img", let imageHandler = imageHandler {
                process(with: imageHandler)
            }
            
            // This element is a supported tag, but it may contain children that aren't,
            // so santize all child nodes to ensure correct tags.
            if let childNodes = childNodes as? [DTHTMLElement] {
                childNodes.forEach { $0.sanitize(with: allowedHTMLTags, bodyFont: font, imageHandler: imageHandler) }
            }
        }
    }
    
    /// Process the element with the supplied image handler.
    private func process(with imageHandler: ImageHandler) {
        // Get the values required to pass to the image handler
        guard let sourceURL = attributes["src"] as? String else { return }
        
        var width: CGFloat = -1
        if let widthString = attributes["width"] as? String,
           let widthDouble = Double(widthString) {
            width = CGFloat(widthDouble)
        }
        
        var height: CGFloat = -1
        if let heightString = attributes["height"] as? String,
           let heightDouble = Double(heightString) {
            height = CGFloat(heightDouble)
        }
        
        // If the handler returns an updated URL, update the text attachment.
        guard let localSourceURL = imageHandler(sourceURL, width, height) else { return }
        textAttachment.contentURL = localSourceURL
    }
}
