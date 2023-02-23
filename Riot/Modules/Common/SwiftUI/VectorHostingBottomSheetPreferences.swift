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

import Foundation

/// `VectorHostingBottomSheetPreferences` defines the bottom sheet behaviour using the `UISheetPresentationController` of the `UIViewController`
class VectorHostingBottomSheetPreferences {
    
    // MARK: - Detent
    
    enum Detent {
        case medium
        case large
        
        /// only available on iOS16, medium behaviour will be used instead
        /// - Parameters:
        ///   - height: The height of the custom detent, if the height is bigger than the maximum possible height for a detent the latter will be returned
        ///   - identifier: The identifier used to identify the custom detent during detent transitions, by default the value is set to "custom", however if you are supporting multiple custom detents in a bottom sheet, you should specify a different identifier for each
        case custom(height: CGFloat, identifier: String = "custom")
        
        @available(iOS 15, *)
        fileprivate func uiSheetDetent() -> UISheetPresentationController.Detent {
            switch self {
            case .medium: return .medium()
            case .large: return .large()
            case let .custom(height, identifier):
                if #available(iOS 16, *) {
                    let identifier = UISheetPresentationController.Detent.Identifier(identifier)
                    return .custom(identifier: identifier) { context in
                        return min(height, context.maximumDetentValue)
                    }
                } else {
                    return .medium()
                }
            }
        }
        
        @available(iOS 15, *)
        fileprivate func uiSheetDetentId() -> UISheetPresentationController.Detent.Identifier {
            switch self {
            case .medium: return .medium
            case .large: return .large
            case let .custom(_, identifier):
                if #available(iOS 16, *) {
                    return UISheetPresentationController.Detent.Identifier(identifier)
                } else {
                    return .medium
                }
            }
        }
    }
    
    // MARK: - Public
    
    // The array of detents that the sheet may rest at.
    // This array must have at least one element.
    // Detents must be specified in order from smallest to largest height.
    // Default: [.medium, .large]
    let detents: [Detent]
    
    // The default detent. When nil or the identifier is not found in detents, the sheet is displayed at the smallest detent.
    // Default: nil
    let defaultDetent: Detent?
    
    // The largest detent that is not dimmed. When nil or the identifier is not found in detents, all detents are dimmed.
    // Default: nil
    let largestUndimmedDetent: Detent?
    let cornerRadius: CGFloat?
    
    // If there is a larger detent to expand to than the selected detent, and a descendent scroll view is scrolled to top, this controls whether scrolling down will expand to a larger detent.
    // Useful to set to NO for non-modal sheets, where scrolling in the sheet should not expand the sheet and obscure the content above.
    // Default: YES
    let prefersScrollingExpandsWhenScrolledToEdge: Bool
    
    // Set to YES to show a grabber at the top of the sheet.
    // Default: `nil` -> the grabber is shown if more than one detent is configured
    let prefersGrabberVisible: Bool?
    
    // MARK: - Setup
    
    init(detents: [Detent] = [.medium, .large],
         defaultDetent: Detent? = nil,
         largestUndimmedDetent: Detent? = nil,
         prefersGrabberVisible: Bool? = nil,
         cornerRadius: CGFloat? = nil,
         prefersScrollingExpandsWhenScrolledToEdge: Bool = true) {
        self.detents = detents
        self.defaultDetent = defaultDetent
        self.largestUndimmedDetent = largestUndimmedDetent
        self.prefersGrabberVisible = prefersGrabberVisible
        self.cornerRadius = cornerRadius
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
    }
    
    // MARK: - Public
    
    func setup(viewController: UIViewController) {
        guard #available(iOS 15.0, *) else { return }
        
        guard let sheetController = viewController.sheetPresentationController else {
            MXLog.debug("[VectorHostingBottomSheetPreferences] setup: no sheetPresentationController found")
            return
        }
        
        sheetController.detents = self.uiSheetDetents()
        if let prefersGrabberVisible = self.prefersGrabberVisible {
            sheetController.prefersGrabberVisible = prefersGrabberVisible
        } else {
            sheetController.prefersGrabberVisible = self.detents.count > 1
        }
        sheetController.selectedDetentIdentifier = self.defaultDetent?.uiSheetDetentId()
        sheetController.largestUndimmedDetentIdentifier = self.largestUndimmedDetent?.uiSheetDetentId()
        sheetController.prefersScrollingExpandsWhenScrolledToEdge = self.prefersScrollingExpandsWhenScrolledToEdge
        if let cornerRadius = self.cornerRadius {
            sheetController.preferredCornerRadius = cornerRadius
        }
    }
    
    // MARK: - Private

    @available(iOS 15, *)
    fileprivate func uiSheetDetents() -> [UISheetPresentationController.Detent] {
        var uiSheetDetents: [UISheetPresentationController.Detent] = []
        for detent in detents {
            uiSheetDetents.append(detent.uiSheetDetent())
        }
        return uiSheetDetents
    }
}
