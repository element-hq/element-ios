/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2018 New Vector Ltd

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
#import <MatrixSDK/MatrixSDK.h>

@class MXKUTI;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMXKAttachmentErrorDomain;

/**
 List attachment types
 */
typedef NS_ENUM(NSUInteger, MXKAttachmentType) {
    MXKAttachmentTypeUndefined,
    MXKAttachmentTypeImage,
    MXKAttachmentTypeAudio,
    MXKAttachmentTypeVoiceMessage,
    MXKAttachmentTypeVideo,
    MXKAttachmentTypeFile,
    MXKAttachmentTypeSticker
};

/**
 `MXKAttachment` represents a room attachment.
 */
@interface MXKAttachment : NSObject

/**
 The media manager instance used to download the attachment data.
 */
@property (nonatomic, readonly) MXMediaManager *mediaManager;

/**
 The attachment type.
 */
@property (nonatomic, readonly) MXKAttachmentType type;

/**
 The attachment information retrieved from the event content during the initialisation.
 */
@property (nonatomic, readonly, nullable) NSString *eventId;
@property (nonatomic, readonly, nullable) NSString *eventRoomId;
@property (nonatomic, readonly) MXEventSentState eventSentState;
@property (nonatomic, readonly, nullable) NSString *contentURL;
@property (nonatomic, readonly, nullable) NSDictionary *contentInfo;

/**
 The URL of a 'standard size' thumbnail.
 */
@property (nonatomic, readonly, nullable) NSString *mxcThumbnailURI;
@property (nonatomic, readonly, nullable) NSString *thumbnailMimeType;

/**
 The download identifier of the attachment content (related to contentURL).
 */
@property (nonatomic, readonly, nullable) NSString *downloadId;
/**
 The download identifier of the attachment thumbnail.
 */
@property (nonatomic, readonly, nullable) NSString *thumbnailDownloadId;

/**
 The attached video thumbnail information.
 */
@property (nonatomic, readonly, nullable) NSDictionary *thumbnailInfo;

/**
 The original file name retrieved from the event body (if any).
 */
@property (nonatomic, readonly, nullable) NSString *originalFileName;

/**
 The thumbnail orientation (relevant in case of image).
 */
@property (nonatomic, readonly) UIImageOrientation thumbnailOrientation;

/**
 The cache file path of the attachment.
 */
@property (nonatomic, readonly, nullable) NSString *cacheFilePath;

/**
 The cache file path of the attachment thumbnail (may be nil).
 */
@property (nonatomic, readonly, nullable) NSString *thumbnailCachePath;

/**
 The preview of the attachment (nil by default).
 */
@property (nonatomic, nullable) UIImage *previewImage;

/**
 True if the attachment is encrypted
 The encryption status of the thumbnail is not covered by this
 property: it is possible for the thumbnail to be encrypted
 whether this peoperty is true or false.
 */
@property (nonatomic, readonly) BOOL isEncrypted;

/**
 The UTI of this attachment.
 */
@property (nonatomic, readonly, nullable) MXKUTI *uti;

/**
 Create a `MXKAttachment` instance for the passed event.
 The created instance copies the current data of the event (content, event id, sent state...).
 It will ignore any future changes of these data.
 
 @param event a matrix event.
 @param mediaManager the media manager instance used to download the attachment data.
 @return `MXKAttachment` instance.
 */
- (nullable instancetype)initWithEvent:(MXEvent*)event andMediaManager:(MXMediaManager*)mediaManager;

- (void)destroy;

/**
 Gets the thumbnail for this attachment if it is in the memory or disk cache,
 otherwise return nil
 */
- (nullable UIImage *)getCachedThumbnail;

/**
 For image attachments, gets a UIImage for the full-res image
 */
- (void)getImage:(void (^_Nullable)(MXKAttachment *_Nullable, UIImage *_Nullable))onSuccess failure:(void (^_Nullable)(MXKAttachment *_Nullable, NSError * _Nullable error))onFailure;

/**
 Decrypt the attachment data into memory and provide it as an NSData
 */
- (void)getAttachmentData:(void (^_Nullable)(NSData *_Nullable))onSuccess failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;

/**
 Decrypts the attachment to a newly created temporary file.
 If the isEncrypted property is YES, this method (or getImage) should be used to
 obtain the full decrypted attachment. The behaviour of this method is undefined
 if isEncrypted is NO.
 It is the caller's responsibility to delete the temporary file once it is no longer
 needed.
 */
- (void)decryptToTempFile:(void (^_Nullable)(NSString *_Nullable))onSuccess failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;


/** Deletes all previously created temporary files */
+ (void)clearCache;

/**
 Gets the thumbnails for this attachment, downloading it or loading it from disk cache
 if necessary
 */
- (void)getThumbnail:(void (^_Nullable)(MXKAttachment *_Nullable, UIImage *_Nullable))onSuccess failure:(void (^_Nullable)(MXKAttachment *_Nullable, NSError * _Nullable error))onFailure;

/**
 Download the attachment data if it is not already cached.
 
 @param onAttachmentReady block called when attachment is available at 'cacheFilePath'.
 @param onFailure the block called on failure.
 */
- (void)prepare:(void (^_Nullable)(void))onAttachmentReady failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;

/**
 Save the attachment in user's photo library. This operation is available only for images and video.
 
 @param onSuccess the block called on success.
 @param onFailure the block called on failure.
 */
- (void)save:(void (^_Nullable)(void))onSuccess failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;

/**
 Copy the attachment data in general pasteboard.
 
 @param onSuccess the block called on success.
 @param onFailure the block called on failure.
 */
- (void)copy:(void (^_Nullable)(void))onSuccess failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;

/**
 Prepare the attachment data to share it. The original name of the attachment (if any) is used
 to name the prepared file.
 
 The developer must call 'onShareEnd' when share operation is ended in order to release potential
 resources allocated here.
 
 @param onReadyToShare the block called when attachment is ready to share at the provided file URL.
 @param onFailure the block called on failure.
 */
- (void)prepareShare:(void (^_Nullable)(NSURL * _Nullable fileURL))onReadyToShare failure:(void (^_Nullable)(NSError * _Nullable error))onFailure;
- (void)onShareEnded;

@end

NS_ASSUME_NONNULL_END
