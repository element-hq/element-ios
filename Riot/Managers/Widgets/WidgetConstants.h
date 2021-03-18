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

/**
 The type of matrix event used for matrix widgets.
 */
FOUNDATION_EXPORT NSString *const kWidgetMatrixEventTypeString;

/**
 The type of matrix event used for modular widgets.
 TODO: It should be replaced by kWidgetMatrixEventTypeString.
 */
FOUNDATION_EXPORT NSString *const kWidgetModularEventTypeString;

/**
 Known types widgets.
 */
FOUNDATION_EXPORT NSString *const kWidgetTypeJitsiV1;
FOUNDATION_EXPORT NSString *const kWidgetTypeJitsiV2;
FOUNDATION_EXPORT NSString *const kWidgetTypeStickerPicker;

@interface WidgetConstants : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
