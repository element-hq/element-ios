//
//  ShareExtensionManager.m
//  Riot
//
//  Created by Aram Sargsyan on 8/10/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import "ShareExtensionManager.h"
@import MobileCoreServices;


@implementation ShareExtensionManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager
{
    static ShareExtensionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)())failureBlock
{
    NSString *UTTypeText = (__bridge NSString *)kUTTypeText;
    NSString *UTTypeURL = (__bridge NSString *)kUTTypeURL;
    NSString *UTTypeImage = (__bridge NSString *)kUTTypeImage;
    NSString *UTTypeVideo = (__bridge NSString *)kUTTypeVideo;
    
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeText])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeText options:nil completionHandler:^(NSString *text, NSError * _Null_unspecified error) {
                    if (!text)
                    {
                        if (failureBlock)
                        {
                            failureBlock();
                        }
                        return;
                    }
                    [room sendTextMessage:text success:^(NSString *eventId) {
                        [self.shareExtensionContext completeRequestReturningItems:@[item] completionHandler:nil];
                    } failure:^(NSError *error) {
                        NSLog(@"[ShareExtensionManager] sendTextMessage failed.");
                        if (failureBlock)
                        {
                            failureBlock();
                        }
                    }];
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeURL])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeURL options:nil completionHandler:^(NSURL *url, NSError * _Null_unspecified error) {
                    if (!url)
                    {
                        if (failureBlock)
                        {
                            failureBlock();
                        }
                        return;
                    }
                    [room sendTextMessage:url.absoluteString success:^(NSString *eventId) {
                        [self.shareExtensionContext completeRequestReturningItems:@[item] completionHandler:nil];
                    } failure:^(NSError *error) {
                        NSLog(@"[ShareExtensionManager] sendTextMessage failed.");
                        if (failureBlock)
                        {
                            failureBlock();
                        }
                    }];
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeImage])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeImage options:nil completionHandler:^(NSData *imageData, NSError * _Null_unspecified error)
                 {
                     if (!imageData)
                     {
                         if (failureBlock)
                         {
                             failureBlock();
                         }
                         return;
                     }
                     //Send the image
                     UIImage *image = [[UIImage alloc] initWithData:imageData];
                     
                     NSString *mimeType;
                     if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePNG])
                     {
                         mimeType = @"image/png";
                     }
                     else if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeJPEG])
                     {
                         mimeType = @"image/jpeg";
                     }
                     else
                     {
                         image = [[UIImage alloc] initWithData:UIImageJPEGRepresentation(image, 1.0)];
                         mimeType = @"image/jpeg";
                     }
                     
                     UIImage *thumbnail = nil;
                     // Thumbnail is useful only in case of encrypted room
                     if (room.state.isEncrypted)
                     {
                         thumbnail = [MXKTools reduceImage:image toFitInSize:CGSizeMake(800, 600)];
                         if (thumbnail == image)
                         {
                             thumbnail = nil;
                         }
                     }
                     [room sendImage:imageData withImageSize:image.size mimeType:mimeType andThumbnail:thumbnail localEcho:nil success:^(NSString *eventId)
                      {
                          [self.shareExtensionContext completeRequestReturningItems:@[item] completionHandler:nil];
                      }
                             failure:^(NSError *error)
                      {
                          NSLog(@"[ShareExtensionManager] sendImage failed.");
                          if (failureBlock)
                          {
                              failureBlock();
                          }
                      }];
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeVideo])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeVideo options:nil completionHandler:^(NSURL *videoLocalUrl, NSError * _Null_unspecified error)
                 {
                     if (!videoLocalUrl)
                     {
                         if (failureBlock)
                         {
                             failureBlock();
                         }
                         return;
                     }
                     
                     // Retrieve the video frame at 1 sec to define the video thumbnail
                     AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:videoLocalUrl options:nil];
                     AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
                     assetImageGenerator.appliesPreferredTrackTransform = YES;
                     CMTime time = CMTimeMake(1, 1);
                     CGImageRef imageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                     // Finalize video attachment
                     UIImage *videoThumbnail = [[UIImage alloc] initWithCGImage:imageRef];
                     CFRelease(imageRef);
                     
                     [room sendVideo:videoLocalUrl withThumbnail:videoThumbnail localEcho:nil success:^(NSString *eventId) {
                         [self.shareExtensionContext completeRequestReturningItems:@[item] completionHandler:nil];
                     } failure:^(NSError *error) {
                         NSLog(@"[ShareExtensionManager] sendVideo failed.");
                         if (failureBlock)
                         {
                             failureBlock();
                         }
                     }];
                     
                 }];
            }
        }
    }
}

- (void)cancelSharing
{
    [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
}

- (void)cancelSharingWithFailure
{
    [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
}


@end
