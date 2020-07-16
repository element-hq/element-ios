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

import QuartzCore

public func CGPathCreateWithSVGString(_ string: String) -> CGPath? {
    let parser = SVGPathStringParser()
    return try? parser.parse(string)
}

class SVGPathStringParser {
    enum Error: Swift.Error {
        case invalidSyntax
        case missingValues
    }

    let path = CGMutablePath()
    var currentPoint = CGPoint()
    var lastControlPoint = CGPoint()

    var command: UnicodeScalar?
    var values = [CGFloat]()

    func parse(_ string: String) throws -> CGPath {
        let tokens = SVGPathStringTokenizer(string: string).tokenize()

        for token in tokens {
            switch token {
            case .command(let c):
                command = c
                values.removeAll()

            case .value(let v):
                values.append(v)
            }

            do {
                try addCommand()
            } catch Error.missingValues {
                // Ignore
            }
        }

        return path
    }

    fileprivate func addCommand() throws {
        guard let command = command else {
            return
        }

        switch command {
        case "M":
            if values.count < 2 { throw Error.missingValues }
            path.move(to: CGPoint(x: values[0], y: values[1]))
            currentPoint = CGPoint(x: values[0], y: values[1])
            lastControlPoint = currentPoint
            values.removeFirst(2)

        case "m":
            if values.count < 2 { throw Error.missingValues }
            let point = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            path.move(to: point)
            currentPoint.x += values[0]
            currentPoint.y += values[1]
            lastControlPoint = currentPoint
            values.removeFirst(2)

        case "L":
            if values.count < 2 { throw Error.missingValues }
            let point = CGPoint(x: values[0], y: values[1])
            path.addLine(to: point)
            currentPoint = CGPoint(x: values[0], y: values[1])
            lastControlPoint = currentPoint
            values.removeFirst(2)

        case "l":
            if values.count < 2 { throw Error.missingValues }
            let point = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            path.addLine(to: point)
            currentPoint.x += values[0]
            currentPoint.y += values[1]
            lastControlPoint = currentPoint
            values.removeFirst(2)

        case "H":
            if values.count < 1 { throw Error.missingValues }
            let point = CGPoint(x: values[0], y: currentPoint.y)
            path.addLine(to: point)
            currentPoint.x = values[0]
            lastControlPoint = currentPoint
            values.removeFirst(1)

        case "h":
            if values.count < 1 { throw Error.missingValues }
            let point = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y)
            path.addLine(to: point)
            currentPoint.x += values[0]
            lastControlPoint = currentPoint
            values.removeFirst(1)

        case "V":
            if values.count < 1 { throw Error.missingValues }
            let point = CGPoint(x: currentPoint.x, y: values[0])
            path.addLine(to: point)
            currentPoint.y = values[0]
            lastControlPoint = currentPoint
            values.removeFirst(1)

        case "v":
            if values.count < 1 { throw Error.missingValues }
            let point = CGPoint(x: currentPoint.x, y: currentPoint.y + values[0])
            path.addLine(to: point)
            currentPoint.y += values[0]
            lastControlPoint = currentPoint
            values.removeFirst(1)

        case "C":
            if values.count < 6 { throw Error.missingValues }
            let c1 = CGPoint(x: values[0], y: values[1])
            let c2 = CGPoint(x: values[2], y: values[3])
            let to = CGPoint(x: values[4], y: values[5])
            path.addCurve(to: to, control1: c1, control2: c2)
            lastControlPoint = c2
            currentPoint = to
            values.removeFirst(6)

        case "c":
            if values.count < 6 { throw Error.missingValues }
            let c1 = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            let c2 = CGPoint(x: currentPoint.x + values[2], y: currentPoint.y + values[3])
            let to = CGPoint(x: currentPoint.x + values[4], y: currentPoint.y + values[5])
            path.addCurve(to: to, control1: c1, control2: c2)
            lastControlPoint = c2
            currentPoint = to
            values.removeFirst(6)

        case "S":
            if values.count < 4 { throw Error.missingValues }
            var c1 = CGPoint()
            c1.x = currentPoint.x + (currentPoint.x - lastControlPoint.x)
            c1.y = currentPoint.y + (currentPoint.y - lastControlPoint.y)
            let c2 = CGPoint(x: values[0], y: values[1])
            let to = CGPoint(x: values[2], y: values[3])
            path.addCurve(to: to, control1: c1, control2: c2)
            lastControlPoint = c2
            currentPoint = to
            values.removeFirst(4)

        case "s":
            if values.count < 4 { throw Error.missingValues }
            var c1 = CGPoint()
            c1.x = currentPoint.x + (currentPoint.x - lastControlPoint.x)
            c1.y = currentPoint.y + (currentPoint.y - lastControlPoint.y)
            let c2 = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            let to = CGPoint(x: currentPoint.x + values[2], y: currentPoint.y + values[3])
            path.addCurve(to: to, control1: c1, control2: c2)
            lastControlPoint = c2
            currentPoint = to
            values.removeFirst(4)

        case "Q":
            if values.count < 4 { throw Error.missingValues }
            let control = CGPoint(x: values[0], y: values[1])
            let to = CGPoint(x: values[2], y: values[3])
            path.addQuadCurve(to: to, control: control)
            lastControlPoint = control
            currentPoint = to
            values.removeFirst(4)

        case "q":
            if values.count < 4 { throw Error.missingValues }
            let control = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            let to = CGPoint(x: currentPoint.x + values[2], y: currentPoint.y + values[3])
            path.addQuadCurve(to: to, control: control)
            lastControlPoint = control
            currentPoint = to
            values.removeFirst(4)

        case "T":
            if values.count < 2 { throw Error.missingValues }
            var control = CGPoint()
            control.x = currentPoint.x + (currentPoint.x - lastControlPoint.x)
            control.y = currentPoint.y + (currentPoint.y - lastControlPoint.y)
            let to = CGPoint(x: values[0], y: values[1])
            path.addQuadCurve(to: to, control: control)
            lastControlPoint = control
            currentPoint = to
            values.removeFirst(2)

        case "t":
            if values.count < 2 { throw Error.missingValues }
            var control = CGPoint()
            control.x = currentPoint.x + (currentPoint.x - lastControlPoint.x)
            control.y = currentPoint.y + (currentPoint.y - lastControlPoint.y)
            let to = CGPoint(x: currentPoint.x + values[0], y: currentPoint.y + values[1])
            path.addQuadCurve(to: to, control: control)
            lastControlPoint = control
            currentPoint = to
            values.removeFirst(2)

        case "Z", "z":
            path.closeSubpath()
            self.command = nil

        default:
            throw Error.invalidSyntax
        }
    }
}

class SVGPathStringTokenizer {
    enum Token {
        case command(UnicodeScalar)
        case value(CGFloat)
    }

    let separatorCharacterSet = CharacterSet(charactersIn: " \t\r\n,")
    let commandCharacterSet = CharacterSet(charactersIn: "mMLlHhVvzZCcSsQqTt")
    let numberStartCharacterSet = CharacterSet(charactersIn: "-+.0123456789")
    let numberCharacterSet = CharacterSet(charactersIn: ".0123456789eE")

    var string: String
    var range: Range<String.UnicodeScalarView.Index>

    init(string: String) {
        self.string = string
        range = string.unicodeScalars.startIndex..<string.unicodeScalars.endIndex
    }

    func tokenize() -> [Token] {
        var array = [Token]()
        while let token = nextToken() {
            array.append(token)
        }
        return array
    }

    func nextToken() -> Token? {
        skipSeparators()

        guard let c = get() else {
            return nil
        }

        if commandCharacterSet.isMember(c) {
            return .command(c)
        }

        if numberStartCharacterSet.isMember(c) {
            var numberString = String(c)
            while let c = peek(), numberCharacterSet.isMember(c) {
                numberString += String(c)
                get()
            }

            if let value = Double(numberString) {
                return .value(CGFloat(value))
            }
        }

        return nil
    }

    @discardableResult
    func get() -> UnicodeScalar? {
        guard range.lowerBound != range.upperBound else {
            return nil
        }
        let c = string.unicodeScalars[range.lowerBound]
        range = string.unicodeScalars.index(after: range.lowerBound)..<range.upperBound
        return c
    }

    func peek() -> UnicodeScalar? {
        guard range.lowerBound != range.upperBound else {
            return nil
        }
        return string.unicodeScalars[range.lowerBound]
    }

    func skipSeparators() {
        while range.lowerBound != range.upperBound && separatorCharacterSet.isMember(string.unicodeScalars[range.lowerBound]) {
            range = string.unicodeScalars.index(after: range.lowerBound)..<range.upperBound
        }
    }

}

extension CharacterSet {
    public func isMember(_ c: UnicodeScalar) -> Bool {
        return contains(UnicodeScalar(c.value)!)
    }
}
