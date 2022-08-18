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

import SwiftUI

struct MultilineTextField: View {
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    @Binding private var text: String
    @State private var dynamicHeight: CGFloat = 100
    @State private var isEditing = false
    
    private var placeholder: String = ""
    
    private var showingPlaceholder: Bool {
        text.isEmpty
    }

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    private var textColor: Color {
        if (theme.identifier == ThemeIdentifier.dark) {
            return theme.colors.primaryContent
        } else {
            return theme.colors.primaryContent
        }
    }
    
    private var backgroundColor: Color {
        return theme.colors.background
    }
    
    private var placeholderColor: Color {
        return theme.colors.tertiaryContent
    }
    
    private var borderColor: Color {
        if isEditing {
            return theme.colors.accent
        }
        
        return theme.colors.quarterlyContent
    }
    
    private var borderWidth: CGFloat {
        return isEditing ? 2.0 : 1.5
    }
    
    var body: some View {
        let rect = RoundedRectangle(cornerRadius: 8.0)
        return UITextViewWrapper(text: $text, calculatedHeight: $dynamicHeight, isEditing: $isEditing)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
            .padding(4.0)
            .background(placeholderView, alignment: .topLeading)
            .animation(.none)
            .background(backgroundColor)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
            .introspectTextView { textView in
                textView.textColor = UIColor(textColor)
                textView.font = theme.fonts.uiFonts.callout
            }
    }

    @ViewBuilder
    private var placeholderView: some View {
        if showingPlaceholder {
            Text(placeholder)
                .foregroundColor(placeholderColor)
                .font(theme.fonts.callout)
                .padding(.leading, 8.0)
                .padding(.top, 12.0)
        }
    }
}

fileprivate struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    @Binding var isEditing: Bool

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        textView.isEditable = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.returnKeyType = .done

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != self.text {
            uiView.text = self.text
        }

        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, isEditing: $isEditing)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var isEditing: Binding<Bool>

        init(text: Binding<String>, height: Binding<CGFloat>, isEditing: Binding<Bool>) {
            self.text = text
            self.calculatedHeight = height
            self.isEditing = isEditing
        }

        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            
            return true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing.wrappedValue = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing.wrappedValue = false
        }
    }
}

struct MultilineTextField_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            VStack {
                PreviewWrapper()
                PlaceholderPreviewWrapper()
                PreviewWrapper()
                    .theme(ThemeIdentifier.dark)
                PlaceholderPreviewWrapper()
                    .theme(ThemeIdentifier.dark)
            }
        }
        .padding()
    }
    
    struct PreviewWrapper: View {
        @State(initialValue: "123") var text: String

        var body: some View {
            MultilineTextField("Placeholder", text: $text)
        }
    }
    
    struct PlaceholderPreviewWrapper: View {
        @State(initialValue: "") var text: String

        var body: some View {
            MultilineTextField("Placeholder", text: $text)
        }
    }
}
