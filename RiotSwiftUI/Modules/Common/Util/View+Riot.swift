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

@available(iOS 13.0, *)
extension View {
    @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

// MARK: - modal presentation mode

fileprivate class PresentationControllerDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
    private let callback: (() -> Void)?
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        callback?()
    }
}
//fileprivate var currentPresentationControllerDelegate: PresentationControllerDelegate? = nil
fileprivate var presentationControllerDelegates: [String: PresentationControllerDelegate] = [:]

@available(iOS 13.0, *)
//fileprivate var currentOverCurrentContextUIHost: UIHostingController<AnyView>? = nil
@available(iOS 13.0, *)
fileprivate var uiHosts: [String: UIHostingController<AnyView>] = [:]

@available(iOS 13.0, *)
extension View {

    func modal<Content>(
        withStyle modalPresentationStyle: UIModalPresentationStyle,
        animated: Bool = true,
        modalTransitionStyle: UIModalTransitionStyle? = nil,
        id: String,
        isPresented: Binding<Bool>,
        content: () -> Content
    ) -> some View where Content: View {
        if isPresented.wrappedValue && uiHosts[id] == nil {
            let uiHost = UIHostingController(rootView: AnyView(content()))
            uiHosts[id] = uiHost

            uiHost.modalPresentationStyle = modalPresentationStyle
            if let modalTransitionStyle = modalTransitionStyle {
                uiHost.modalTransitionStyle = modalTransitionStyle
            }
            uiHost.view.backgroundColor = UIColor.clear
            presentationControllerDelegates[id] = PresentationControllerDelegate(callback: {
                isPresented.wrappedValue = false
            })
            uiHost.presentationController?.delegate = presentationControllerDelegates[id]

            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                frontmostPresentedViewController(from: rootVC)?.present(uiHost, animated: animated, completion: nil)
            }
        } else {
            if let uiHost = uiHosts[id] {
                uiHost.dismiss(animated: animated, completion: {})
                uiHosts.removeValue(forKey: id)
                presentationControllerDelegates.removeValue(forKey: id)
            }
        }

        return self
    }

    fileprivate func frontmostPresentedViewController(from viewController: UIViewController) -> UIViewController? {
        var frontMostController = viewController
        while let presentedViewController = frontMostController.presentedViewController {
            frontMostController = presentedViewController
        }
        
        return frontMostController
    }
    
}
