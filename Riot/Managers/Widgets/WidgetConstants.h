// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
