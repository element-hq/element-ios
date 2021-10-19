/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

@import UIKit;

@class ShareViewController;
@class ShareDataSource;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ShareViewControllerType) {
    ShareViewControllerTypeSend,
    ShareViewControllerTypeForward
};

typedef NS_ENUM(NSUInteger, ShareViewControllerAccountState) {
    ShareViewControllerAccountStateConfigured,
    ShareViewControllerAccountStateNotConfigured
};

@protocol ShareViewControllerDelegate <NSObject>

- (void)shareViewController:(ShareViewController *)shareViewController didRequestShareForRoomIdentifiers:(NSSet<NSString *> *)roomIdentifiers;
- (void)shareViewControllerDidRequestDismissal:(ShareViewController *)shareViewController;

@end

@interface ShareViewController : UIViewController

@property (nonatomic, weak, nullable) id<ShareViewControllerDelegate> delegate;

- (instancetype)initWithType:(ShareViewControllerType)type
                currentState:(ShareViewControllerAccountState)state;

- (void)configureWithState:(ShareViewControllerAccountState)state
            roomDataSource:(nullable ShareDataSource *)roomDataSource;

- (void)showProgressIndicator;

- (void)setProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
