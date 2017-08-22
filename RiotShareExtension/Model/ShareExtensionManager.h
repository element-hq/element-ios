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

/**
 Posted when the matrix session has been changed.
 The notification object is the matrix session.
 */
extern NSString *const kShareExtensionManagerDidChangeMXSessionNotification;

/**
 The protocol for the manager's delegate
 */
@protocol ShareExtensionManagerDelegate <NSObject>

@required

/**
 Called when an image is going to be shared to show a compression prompt
 @param extensionManager the ShareExtensionManager object that called the method
 @param compressionPrompt the prompt that was prepared for the image which is going to be shared
 */
- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager showImageCompressionPrompt:(UIAlertController *)compressionPrompt;

@optional

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager didStartSendingContentToRoom:(MXRoom *)room;

/**
 Called when the progress of the uploading media changes
 @param extensionManager the ShareExtensionManager object that called the method
 @param progress the current progress
 */
- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager mediaUploadProgress:(CGFloat)progress;

@end


/**
 A class used to share content from the extension
 */

@interface ShareExtensionManager : NSObject

/**
 The share extension context that represents a user's sharing request, also stores the content to be shared
 */
@property (nonatomic) NSExtensionContext *shareExtensionContext;

/**
 The associated matrix session (nil by default).
 */
@property (nonatomic, readonly) MXSession *mxSession;

/**
 A delegate used to notify about needed UI changes when sharing
 */
@property (nonatomic) id<ShareExtensionManagerDelegate> delegate;

/**
 The singleton instance
 */
+ (instancetype)sharedManager;

/**
 Send the content that the user has chosen to a room
 @param room the room to send the content to
 @param failureBlock the code to be executed when sharing has failed for whatever reason
 note: there is no "successBlock" parameter because when the sharing succeds, the extension needs to close itself
 */
- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)())failureBlock;

/**
 Checks if there is an image in the user chosen content
 @return YES if there is, NO otherwise
 */
- (BOOL)hasImageTypeContent;

/**
 Terminate the extension and return to the app that started it
 @param canceled YES if the user chose to cancel the sharing, NO otherwise
 */
- (void)terminateExtensionCanceled:(BOOL)canceled;

@end


@interface NSItemProvider (ShareExtensionManager)

@property BOOL isLoaded;

@end
