// 
// Copyright 2020 New Vector Ltd
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

extension UIImageView {
    
    func vc_updateAspectRatioConstraint(withPriority priority: UILayoutPriority = .required) {
        guard let image = self.image else {
            return
        }
        
        
        vc_removeAspectRatioConstraint()
        let aspectRatio = image.size.width / image.size.height
        let constraint = NSLayoutConstraint(item: self, attribute: .width,
                                            relatedBy: .equal,
                                            toItem: self, attribute: .height,
                                            multiplier: aspectRatio, constant: 0.0)
        constraint.priority = priority
        self.addConstraint(constraint)
    }
    
    func vc_removeAspectRatioConstraint() {
        for constraint in self.constraints {
            if (constraint.firstItem as? UIImageView) == self,
               (constraint.secondItem as? UIImageView) == self {
                removeConstraint(constraint)
            }
        }
    }
}
