// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Element)

/// Returns an array containing the results of mapping the given closure over the array's elements.
/// @param transform A mapping closure. `transform` accepts an element of this array as its parameter
/// and returns a transformed value of the same or of a different type.
/// @return An array containing the transformed elements of this array.
- (NSArray *)vc_map:(id (^)(id obj))transform;

/// Returns an array containing the non-nil results of mapping the given closure over the array's elements.
/// @param transform A mapping closure. `transform` accepts an element of this array as its parameter
/// and returns a nullable transformed value of the same or of a different type.
/// @return An array of the non-nil results of calling `transform` with each element of the array.
- (NSArray *)vc_compactMap:(id _Nullable (^)(id obj))transform;

/// Returns an array containing the concatenated results of mapping the given closure over the array's elements.
/// @param transform A mapping closure. `transform` accepts an element of this array as its parameter
/// and returns an array..
/// @return The resulting flattened array.
- (NSArray *)vc_flatMap:(NSArray* (^)(id obj))transform;

@end

NS_ASSUME_NONNULL_END
