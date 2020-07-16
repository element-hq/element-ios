// Copyright © 2016-2019 JABT Labs Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

import Foundation
import UIKit

public extension CAMediaTimingFunction {
    static let linear = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    static let easeIn = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    static let easeOut = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    static let easeInEaseOut = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

    var reversed: CAMediaTimingFunction {
        let (c1, c2) = controlPoints
        let x1 = Float(1 - c2.x)
        let y1 = Float(1 - c2.y)
        let x2 = Float(1 - c1.x)
        let y2 = Float(1 - c1.y)
        return CAMediaTimingFunction(controlPoints: x1, y1, x2, y2)
    }

    var controlPoints: (CGPoint, CGPoint) {
        var c1: [Float] = [0, 0]
        var c2: [Float] = [0, 0]
        getControlPoint(at: 1, values: &c1)
        getControlPoint(at: 2, values: &c2)

        let c1x = CGFloat(c1[0])
        let c1y = CGFloat(c1[1])
        let c2x = CGFloat(c2[0])
        let c2y = CGFloat(c2[1])

        return (CGPoint(x: c1x, y: c1y), CGPoint(x: c2x, y: c2y))
    }
}
