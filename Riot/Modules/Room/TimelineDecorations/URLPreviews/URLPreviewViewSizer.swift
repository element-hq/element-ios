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
// limitations under the Lircense.
//

import Foundation

/// `URLPreviewViewSizer` allows to determine reactions view height for a given urlPreviewData and width.
class URLPreviewViewSizer {
    
    // MARK: - Constants
    
    private static let sizingView = URLPreviewView.instantiate()    
    
    // MARK: - Public
    
    func height(for urlPreviewData: URLPreviewData, fittingWidth width: CGFloat) -> CGFloat {
        
        let sizingView = URLPreviewViewSizer.sizingView
        
        sizingView.frame.size.height = 1.0
        sizingView.preview = urlPreviewData
        sizingView.availableWidth = width
        
        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()
        
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        
        return sizingView.systemLayoutSizeFitting(fittingSize).height
    }
}
