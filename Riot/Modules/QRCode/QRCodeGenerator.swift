/*
 Copyright 2020 New Vector Ltd
 
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

final class QRCodeGenerator {
    
    // MARK: - Constants
    
    private enum Constants {
        static let qrCodeGeneratorFilter = "CIQRCodeGenerator"
        static let qrCodeInputCorrectionLevel = "M"
    }
    
    // MARK: - Public
    
    func generateCode(from data: Data, with size: CGSize) -> UIImage? {
        guard let filter = CIFilter(name: Constants.qrCodeGeneratorFilter) else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(Constants.qrCodeInputCorrectionLevel, forKey: "inputCorrectionLevel") // Be sure to use same error resilience level as other platform
        
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        let scaleX = size.width/ciImage.extent.size.width
        let scaleY = size.height/ciImage.extent.size.height
        
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            
        let transformedCIImage = ciImage.transformed(by: transform)
        return UIImage(ciImage: transformedCIImage)
    }
}
