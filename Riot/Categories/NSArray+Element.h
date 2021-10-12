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
// limitations under the License.
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
