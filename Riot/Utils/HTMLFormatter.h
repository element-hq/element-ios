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
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTMLFormatter : NSObject

/** Builds an attributed string from a string containing html.
 @param htmlString The html string to use.
 @param allowedTags The html tags that should be allowed.
 @param fontSize The default font size to use.
 
 Note: It is recommended to include "p" and "body" tags in
 `allowedTags` as these are often added when parsing.
 */
- (NSAttributedString * _Nonnull)formatHTML:(NSString * _Nonnull)htmlString
                            withAllowedTags:(NSArray<NSString *> * _Nonnull)allowedTags
                                   fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
