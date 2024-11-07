/*
Copyright 2024 New Vector Ltd.
Copyright 2020 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MXKPreviewViewControllerDelegate;

/**
 @brief A view controller that previews, opens, or prints files whose file format cannot be handled directly by your app.
 
 Use this class to present an appropriate user interface for previewing, opening, copying, or printing a specified file. For example, an email program might use this class to allow the user to preview attachments and open them in other apps.
 
 After presenting its user interface, a document interaction controller handles all interactions needed to support file preview and menu display.
 
 Unlike UIDocumentInteractionController, this view controller aims to be modal presented.
 */
@interface MXKPreviewViewController : UINavigationController

/**
 @brief presents a new instance of MXKPreviewViewController as modal.
 
 @param presenting view controller that presents the MXKPreviewViewController
 @param fileUrl URL of the file. This URL should point to a local file.
 @param allowActions YES to display actions Button. NO otherwise
 @param delegate delegate (optional) that receives some events about the lifecycle of the MXKPreviewViewController
 
 @return the instance of MXKPreviewViewController
 */
+ (MXKPreviewViewController *)presentFrom:(nonnull UIViewController *)presenting
            fileUrl: (nonnull NSURL *)fileUrl
       allowActions: (BOOL)allowActions
           delegate: (nullable id<MXKPreviewViewControllerDelegate>)delegate;

@end

/**
 A set of methods you can implement to respond to messages from a preview controller.
 */
@protocol MXKPreviewViewControllerDelegate <NSObject>

@optional

/**
 The MXKPreviewViewController will present the preview
 
 @param controller the instance of MXKPreviewViewController
 */
- (void)previewViewControllerWillBeginPreview:(MXKPreviewViewController *)controller;

/**
 The MXKPreviewViewController did end presenting the preview
 
 @param controller the instance of MXKPreviewViewController
 */
- (void)previewViewControllerDidEndPreview:(MXKPreviewViewController *)controller;

@end

NS_ASSUME_NONNULL_END
