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
        do {
            let ast = try DownASTRenderer.stringToAST(markdown, options: options)
            defer {
                cmark_node_free(ast)
            }
            ast.repairLinks()
            return try DownHTMLRenderer.astToHTML(ast, options: options)
        } catch {
            MXLog.error("[MarkdownToHTMLRenderer] renderToHTML failed")
            return nil
        }
    }
    
}

@objcMembers
public class MarkdownToHTMLRendererHardBreaks: MarkdownToHTMLRenderer {
    
    public override init() {
        super.init()
        options = .hardBreaks
    }
    
}

// MARK: - AST-handling private extensions
private extension CMarkNode {
    /// Formatting symbol associated with given note type
    /// Note: this is only defined for node types that are handled in repairLinks
    var formattingSymbol: String {
        switch self.type {
        case CMARK_NODE_EMPH:
            return "_"
        case CMARK_NODE_STRONG:
            return "__"
        default:
            return ""
        }
    }

    /// Repairs links that were broken down by markdown formatting.
    /// Should be used on the first node of libcmark's AST
    /// (e.g. the object returned by DownASTRenderer.stringToAST).
    func repairLinks() {
        let iterator = cmark_iter_new(self)
        var text = ""
        var isInParagraph = false
        var previousNode: CMarkNode?
        var orphanNodes: [CMarkNode] = []
        var shouldUnlinkFormattingMode = false
        var event: cmark_event_type?
        while event != CMARK_EVENT_DONE {
            event = cmark_iter_next(iterator)

            guard let node = cmark_iter_get_node(iterator) else { return }

            if node.type == CMARK_NODE_PARAGRAPH {
                if event == CMARK_EVENT_ENTER {
                    isInParagraph = true
                } else {
                    isInParagraph = false
                    text = ""
                }
            }

            if isInParagraph {
                switch node.type {
                case CMARK_NODE_SOFTBREAK,
                     CMARK_NODE_LINEBREAK:
                    text = ""
                case CMARK_NODE_TEXT:
                    if let literal = node.literal {
                        text += literal
                        // Reset text if it ends up with a whitespace.
                        if text.last?.isWhitespace == true {
                            text = ""
                        }
                        // Only the last part could be a link conflicting with next node.
                        text = String(text.split(separator: " ").last ?? "")
                    }
                case CMARK_NODE_EMPH where previousNode?.type == CMARK_NODE_TEXT,
                     CMARK_NODE_STRONG where previousNode?.type == CMARK_NODE_TEXT:
                    if event == CMARK_EVENT_ENTER {
                        if !text.containedUrls.isEmpty,
                           let childLiteral = node.pointee.first_child.literal {
                            // If current text is a link, the formatted text is reverted back to a
                            // plain text as a part of the link.
                            let symbol = node.formattingSymbol
                            let nonFormattedText = "\(symbol)\(childLiteral)\(symbol)"
                            let replacementTextNode = cmark_node_new(CMARK_NODE_TEXT)
                            cmark_node_set_literal(replacementTextNode, nonFormattedText)
                            cmark_node_insert_after(previousNode, replacementTextNode)
                            // Set child literal to empty string so we dont read it.
                            // This avoids having to re-create the main
                            // iterator in the middle of the process.
                            cmark_node_set_literal(node.pointee.first_child, "")
                            let newIterator = cmark_iter_new(node)
                            _ = cmark_iter_next(newIterator)
                            cmark_node_unlink(node)
                            orphanNodes.append(node)
                            let nextNode = cmark_iter_get_node(newIterator)
                            cmark_node_insert_after(previousNode, nextNode)
                            shouldUnlinkFormattingMode = true
                        }
                    } else {
                        if shouldUnlinkFormattingMode {
                            cmark_node_unlink(node)
                            orphanNodes.append(node)
                            shouldUnlinkFormattingMode = false
                        }
                    }
                default:
                    break
                }
            }
            previousNode = node
        }

        // Free all nodes removed from the AST.
        // This is done as a last step to avoid messing
        // up with the main itertor.
        for orphanNode in orphanNodes {
            cmark_node_free(orphanNode)
        }
    }
}

private extension String {
    /// Returns array of URLs detected inside the String.
    var containedUrls: [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        return detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
    }
}
