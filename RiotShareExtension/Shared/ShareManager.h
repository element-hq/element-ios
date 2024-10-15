/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@protocol ShareItemSenderProtocol;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ShareManagerType) {
    ShareManagerTypeSend,
    ShareManagerTypeForward,
};

typedef NS_ENUM(NSUInteger, ShareManagerResult) {
    ShareManagerResultFinished,
    ShareManagerResultCancelled,
    ShareManagerResultFailed
};

@interface ShareManager : NSObject

@property (nonatomic, copy) void (^completionCallback)(ShareManagerResult);

- (instancetype)initWithShareItemSender:(id<ShareItemSenderProtocol>)itemSender
                                   type:(ShareManagerType)type
                                   session:(nullable MXSession*)session;


- (UIViewController *)mainViewController;

@end


NS_ASSUME_NONNULL_END
