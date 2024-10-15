/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import ImageIO
import MobileCoreServices

// We do not use the SwiftUTI pod anymore
// The library is embedded in MatrixKit. See Libs/SwiftUTI/README.md for more details
// import SwiftUTI

/// MXKUTI represents a Universal Type Identifier (e.g. kUTTypePNG).
/// See https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html#//apple_ref/doc/uid/TP40001319-CH202-SW5 for more information.
/// MXKUTI wraps UTI class from SwiftUTI library (https://github.com/mkeiser/SwiftUTI) to make it available for Objective-C.
@objcMembers
open class MXKUTI: NSObject, RawRepresentable {
    
    public typealias RawValue = String
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let utiWrapper: UTI
    
    // MARK: Public
    
    /// UTI string
    public var rawValue: String {
        return utiWrapper.rawValue
    }
    
    /// Return associated prefered file extension (e.g. "png").
    public var fileExtension: String? {
        return utiWrapper.fileExtension
    }
    
    /// Return associated prefered mime-type (e.g. "image/png").
    public var mimeType: String? {
        return utiWrapper.mimeType
    }
    
    // MARK: - Setup
    
    // MARK: Private
    
    private init(utiWrapper: UTI) {
        self.utiWrapper = utiWrapper
        super.init()
    }
    
    // MARK: Public
    
    /// Initialize with UTI String.
    /// Note: Although this initializer is marked as failable, due to RawRepresentable conformity, it cannot fail.
    ///
    /// - Parameter rawValue: UTI String (e.g. "public.png").
    public required init?(rawValue: String) {
        let utiWrapper = UTI(rawValue: rawValue)
        self.utiWrapper = utiWrapper
        super.init()
    }
    
    /// Initialize with UTI CFString.
    ///
    /// - Parameter cfRawValue: UTI CFString (e.g. kUTTypePNG).
    public convenience init?(cfRawValue: CFString) {
        self.init(rawValue: cfRawValue as String)
    }
    
    /// Initialize with file extension.
    ///
    /// - Parameter fileExtension: A file extesion (e.g. "png").
    public convenience init(fileExtension: String) {
        let utiWrapper = UTI(withExtension: fileExtension)
        self.init(utiWrapper: utiWrapper)
    }
    
    /// Initialize with MIME type.
    ///
    /// - Parameter mimeType: A MIME type (e.g. "image/png").
    public convenience init?(mimeType: String) {
        let utiWrapper = UTI(withMimeType: mimeType)
        self.init(utiWrapper: utiWrapper)
    }
    
    /// Check current UTI conformance with another UTI.
    ///
    /// - Parameter otherUTI: UTI which to conform with.
    /// - Returns: true if self conforms to other UTI.
    public func conforms(to otherUTI: MXKUTI) -> Bool {
        return self.utiWrapper.conforms(to: otherUTI.utiWrapper)
    }
    
    /// Check whether the current UTI conforms to any UTIs within an array.
    ///
    /// - Parameter otherUTIs: UTI which to conform with.
    /// - Returns: true if self conforms to any of the other UTIs.
    public func conformsToAny(of otherUTIs: [MXKUTI]) -> Bool {
        for uti in otherUTIs {
            if conforms(to: uti) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Other convenients initializers
extension MXKUTI {
    
    /// Initialize with image data.
    ///
    /// - Parameter imageData: Image data.
    convenience init?(imageData: Data) {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let uti = CGImageSourceGetType(imageSource) else {
                return nil
        }
        self.init(rawValue: uti as String)
    }
    
    // swiftlint:disable unused_optional_binding
    
    /// Initialize with local file URL.
    /// This method is currently applicable only to URLs for file system resources.
    ///
    /// - Parameters:
    ///   - localFileURL: Local file URL.
    ///   - loadResourceValues: Indicate true to prefetch `typeIdentifierKey` URLResourceKey
    convenience init?(localFileURL: URL, loadResourceValues: Bool = true) {
        if loadResourceValues,
            let _ = try? FileManager.default.contentsOfDirectory(at: localFileURL.deletingLastPathComponent(), includingPropertiesForKeys: [.typeIdentifierKey], options: []),
            let uti = try? localFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            self.init(rawValue: uti)
        } else if localFileURL.pathExtension.isEmpty == false {
            let fileExtension = localFileURL.pathExtension
            self.init(fileExtension: fileExtension)
        } else {
            return nil
        }
    }
    
    // swiftlint:enable unused_optional_binding
    
    public convenience init?(localFileURL: URL) {
        self.init(localFileURL: localFileURL, loadResourceValues: true)
    }
}

// MARK: - Convenients conformance UTIs methods
extension MXKUTI {
    public var isImage: Bool {
        return self.conforms(to: MXKUTI.image)
    }
    
    public var isVideo: Bool {
        return self.conforms(to: MXKUTI.movie)
    }
    
    public var isFile: Bool {
        return self.conforms(to: MXKUTI.data)
    }
}

// swiftlint:disable force_unwrapping

// MARK: - Some system defined UTIs
extension MXKUTI {
    public static let data = MXKUTI(cfRawValue: kUTTypeData)!
    public static let text = MXKUTI(cfRawValue: kUTTypeText)!
    public static let audio = MXKUTI(cfRawValue: kUTTypeAudio)!
    public static let video = MXKUTI(cfRawValue: kUTTypeVideo)!
    public static let movie = MXKUTI(cfRawValue: kUTTypeMovie)!
    public static let image = MXKUTI(cfRawValue: kUTTypeImage)!
    public static let png = MXKUTI(cfRawValue: kUTTypePNG)!
    public static let jpeg = MXKUTI(cfRawValue: kUTTypeJPEG)!
    public static let svg = MXKUTI(cfRawValue: kUTTypeScalableVectorGraphics)!
    public static let url = MXKUTI(cfRawValue: kUTTypeURL)!
    public static let fileUrl = MXKUTI(cfRawValue: kUTTypeFileURL)!
    public static let html = MXKUTI(cfRawValue: kUTTypeHTML)!
    public static let xml = MXKUTI(cfRawValue: kUTTypeXML)!
}

// swiftlint:enable force_unwrapping

// MARK: - Convenience static methods
extension MXKUTI {
    
    public static func mimeType(from fileExtension: String) -> String? {
        return MXKUTI(fileExtension: fileExtension).mimeType
    }
    
    public static func fileExtension(from mimeType: String) -> String? {
        return MXKUTI(mimeType: mimeType)?.fileExtension
    }
}
