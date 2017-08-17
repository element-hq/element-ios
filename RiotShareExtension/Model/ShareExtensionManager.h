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

#import <Foundation/Foundation.h>
#import <MatrixKit/MatrixKit.h>

@class ShareExtensionManager;

@protocol ShareExtensionManagerDelegate <NSObject>

@required

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager showImageCompressionPrompt:(UIAlertController *)compressionPrompt;

@optional

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager mediaUploadProgress:(CGFloat)progress;

@end

@interface ShareExtensionManager : NSObject

@property (nonatomic) NSExtensionContext *shareExtensionContext;

@property (nonatomic) id<ShareExtensionManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)())failureBlock;

- (BOOL)hasImageTypeContent;

- (void)cancelSharing;

- (void)cancelSharingWithFailure;

- (UIAlertController *)compressionPromptForImage:(UIImage *)image shareBlock:(nonnull void(^)())shareBlock;

@end
