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

struct ThemableTextEditor: UIViewRepresentable {
    // MARK: Properties
    
    @Binding var text: String
    @State var configuration = UIKitTextInputConfiguration()
    var onEditingChanged: ((_ edit: Bool) -> Void)?

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    private let textView = UITextView()
    private let internalParams = InternalParams()
    
    // MARK: Setup
    
    init(text: Binding<String>,
         configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration(),
         onEditingChanged: ((_ edit: Bool) -> Void)? = nil) {
        _text = text
        _configuration = State(initialValue: configuration)
        self.onEditingChanged = onEditingChanged
        
        ResponderManager.register(view: textView)
    }

    // MARK: UIViewRepresentable
    
    func makeUIView(context: Context) -> UITextView {
        textView.delegate = context.coordinator
        textView.text = text
        
        if internalParams.isFirstResponder {
            textView.becomeFirstResponder()
        }

        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.backgroundColor = .clear
        uiView.font = UIFont.preferredFont(forTextStyle: .callout)
        uiView.textColor = UIColor(theme.colors.primaryContent)
        uiView.tintColor = UIColor(theme.colors.accent)
        
        if uiView.text != text {
            uiView.text = text
        }

        uiView.keyboardType = configuration.keyboardType
        uiView.returnKeyType = configuration.returnKeyType
        uiView.isSecureTextEntry = configuration.isSecureTextEntry
        uiView.autocapitalizationType = configuration.autocapitalizationType
        uiView.autocorrectionType = configuration.autocorrectionType
    }
    
    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        ResponderManager.unregister(view: uiView)
    }
    
    // MARK: - Private
    
    private func replaceText(with newText: String) {
        text = newText
    }

    private class InternalParams {
        var isFirstResponder = false
    }

    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ThemableTextEditor
        
        init(_ parent: ThemableTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onEditingChanged?(true)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onEditingChanged?(false)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            guard let text = textView.text else {
                return
            }

            parent.replaceText(with: text)
        }
        
        @objc func wakeUpNextResponder() {
            if !ResponderManager.makeActiveNextResponder(of: parent.textView) {
                parent.textView.resignFirstResponder()
            }
        }
    }
}

// MARK: - modifiers

extension ThemableTextEditor {
    func keyboardType(_ type: UIKeyboardType) -> ThemableTextEditor {
        textView.keyboardType = type
        return self
    }
    
    func isSecureTextEntry(_ isSecure: Bool) -> ThemableTextEditor {
        textView.isSecureTextEntry = isSecure
        return self
    }
    
    func returnKeyType(_ type: UIReturnKeyType) -> ThemableTextEditor {
        textView.returnKeyType = type
        return self
    }
    
    func autocapitalizationType(_ type: UITextAutocapitalizationType) -> ThemableTextEditor {
        textView.autocapitalizationType = type
        return self
    }
    
    func autocorrectionType(_ type: UITextAutocorrectionType) -> ThemableTextEditor {
        textView.autocorrectionType = type
        return self
    }
    
    func makeFirstResponder() -> ThemableTextEditor {
        internalParams.isFirstResponder = true
        return self
    }
}
