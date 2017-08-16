//
//  ShareExtensionManager.h
//  Riot
//
//  Created by Aram Sargsyan on 8/10/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

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
