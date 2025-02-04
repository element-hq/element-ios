//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct BorderModifier<Shape: InsettableShape>: ViewModifier {
    var color: Color
    var borderWidth: CGFloat
    var shape: Shape
    
    func body(content: Content) -> some View {
        content
            .overlay(shape.stroke(color, lineWidth: borderWidth))
    }
}

extension View {
    func shapedBorder<Shape: InsettableShape>(color: Color, borderWidth: CGFloat, shape: Shape) -> some View {
        modifier(BorderModifier(color: color, borderWidth: borderWidth, shape: shape))
    }
}
