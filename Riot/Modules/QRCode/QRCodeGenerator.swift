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
import ZXingObjC
import UIKit

final class QRCodeGenerator {
    enum Error: Swift.Error {
        case cannotCreateImage
    }
    
    func generateCode(from data: Data,
                      with size: CGSize,
                      onColor: UIColor = .black,
                      offColor: UIColor = .white) throws -> UIImage {
        let writer = ZXMultiFormatWriter()
        let endodedString = String(data: data, encoding: .isoLatin1)
        let scale = UIScreen.main.scale
        let bitMatrix = try writer.encode(
            endodedString,
            format: kBarcodeFormatQRCode,
            width: Int32(size.width * scale),
            height: Int32(size.height * scale),
            hints: ZXEncodeHints()
        )

        guard let cgImage = ZXImage(matrix: bitMatrix,
                                    on: onColor.cgColor,
                                    offColor: offColor.cgColor).cgimage else {
            throw Error.cannotCreateImage
        }
        
        return UIImage(cgImage: cgImage)
    }
}
