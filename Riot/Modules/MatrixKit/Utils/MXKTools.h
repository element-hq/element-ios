/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define MXKTOOLS_LARGE_IMAGE_SIZE    1024
#define MXKTOOLS_MEDIUM_IMAGE_SIZE   768
#define MXKTOOLS_SMALL_IMAGE_SIZE    512

#define MXKTOOLS_USER_IDENTIFIER_BITWISE  0x01
#define MXKTOOLS_ROOM_IDENTIFIER_BITWISE  0x02
#define MXKTOOLS_ROOM_ALIAS_BITWISE       0x04
#define MXKTOOLS_EVENT_IDENTIFIER_BITWISE 0x08

// Attribute in an NSAttributeString that marks a blockquote block that was in the original HTML string.
extern NSString *const kMXKToolsBlockquoteMarkAttribute;

/**
 Structure representing an the size of an image and its file size.
 */
typedef struct
{
    CGSize imageSize;
    NSUInteger fileSize;
    
} MXKImageCompressionSize;

/**
 Structure representing the sizes of image (image size and file size) according to
 different level of compression.
 */

typedef struct
{
    MXKImageCompressionSize small;
    MXKImageCompressionSize medium;
    MXKImageCompressionSize large;
    MXKImageCompressionSize original;
    
    CGFloat actualLargeSize;
    
} MXKImageCompressionSizes;

@interface MXKTools : NSObject

#pragma mark - Strings

/**
 Determine if a string contains one emoji and only one.
 
 @param string the string to check.
 @return YES if YES.
 */
+ (BOOL)isSingleEmojiString:(NSString*)string;

/**
 Determine if a string contains only emojis.

 @param string the string to check.
 @return YES if YES.
 */
+ (BOOL)isEmojiOnlyString:(NSString*)string;

#pragma mark - Time

/**
 Format time interval.
 ex: "5m 31s".
 
 @param secondsInterval time interval in seconds.
 @return formatted string
 */
+ (NSString*)formatSecondsInterval:(CGFloat)secondsInterval;

/**
 Format time interval but rounded to the nearest time unit below.
 ex: "5s", "1m", "2h" or "3d".

 @param secondsInterval time interval in seconds.
 @return formatted string
 */
+ (NSString*)formatSecondsIntervalFloored:(CGFloat)secondsInterval;

#pragma mark - Phone number

/**
 Return the number used to identify a mobile phone number internationally.
 
 The provided country code is ignored when the phone number is already internationalized, or when it
 is a valid msisdn.
 
 @param phoneNumber the phone number.
 @param countryCode the ISO 3166-1 country code representation (required when the phone number is in national format).
 
 @return a valid msisdn or nil if the provided phone number is invalid.
 */
+ (NSString*)msisdnWithPhoneNumber:(NSString *)phoneNumber andCountryCode:(NSString *)countryCode;

/**
 Format an MSISDN to a human readable international phone number.

 @param msisdn The MSISDN to format.
 
 @return Human readable international phone number.
 */
+ (NSString*)readableMSISDN:(NSString*)msisdn;

#pragma mark - Hex color to UIColor conversion

/**
 Build a UIColor from an hexadecimal color value
 
 @param rgbValue the color expressed in hexa (0xRRGGBB)
 @return the UIColor
 */
+ (UIColor*)colorWithRGBValue:(NSUInteger)rgbValue;

/**
 Build a UIColor from an hexadecimal color value with transparency

 @param argbValue the color expressed in hexa (0xAARRGGBB)
 @return the UIColor
 */
+ (UIColor*)colorWithARGBValue:(NSUInteger)argbValue;

/**
 Return an hexadecimal color value from UIColor
 
 @param color the UIColor
 @return rgbValue the color expressed in hexa (0xRRGGBB)
 */
+ (NSUInteger)rgbValueWithColor:(UIColor*)color;

/**
 Return an hexadecimal color value with transparency from UIColor
 
 @param color the UIColor
 @return argbValue the color expressed in hexa (0xAARRGGBB)
 */
+ (NSUInteger)argbValueWithColor:(UIColor*)color;

#pragma mark - Image processing

/**
 Force image orientation to up
 
 @param imageSrc the original image.
 @return image with `UIImageOrientationUp` orientation.
 */
+ (UIImage*)forceImageOrientationUp:(UIImage*)imageSrc;

/**
 Return struct MXKImageCompressionSizes representing the available compression sizes for the image
 
 @param image the image to get available sizes for
 @param originalFileSize the size in bytes of the original image file or the image data (0 if this value is unknown).
 */
+ (MXKImageCompressionSizes)availableCompressionSizesForImage:(UIImage*)image originalFileSize:(NSUInteger)originalFileSize;

/**
 Compute image size to fit in specific box size (in aspect fit mode)
 
 @param originalSize the original size
 @param maxSize the box size
 @param canExpand tell whether the image can be expand or not
 @return the resized size.
 */
+ (CGSize)resizeImageSize:(CGSize)originalSize toFitInSize:(CGSize)maxSize canExpand:(BOOL)canExpand;

/**
 Compute image size to fill specific box size (in aspect fill mode)
 
 @param originalSize the original size
 @param maxSize the box size
 @param canExpand tell whether the image can be expand or not
 @return the resized size.
 */
+ (CGSize)resizeImageSize:(CGSize)originalSize toFillWithSize:(CGSize)maxSize canExpand:(BOOL)canExpand;

/**
 Reduce image to fit in the provided size.
 The aspect ratio is kept.
 If the image is smaller than the provided size, the image is not recomputed.
 
 @discussion This method call `+ [reduceImage:toFitInSize:useMainScreenScale:]` with `useMainScreenScale` value to `NO`.
 
 @param image the image to modify.
 @param size to fit in.
 @return resized image.
 
 @see reduceImage:toFitInSize:useMainScreenScale:
 */
+ (UIImage *)reduceImage:(UIImage *)image toFitInSize:(CGSize)size;

/**
 Reduce image to fit in the provided size.
 The aspect ratio is kept.
 If the image is smaller than the provided size, the image is not recomputed.
 
 @param image the image to modify.
 @param size to fit in.
 @param useMainScreenScale Indicate true to use main screen scale.
 @return resized image.
 */
+ (UIImage *)reduceImage:(UIImage *)image toFitInSize:(CGSize)size useMainScreenScale:(BOOL)useMainScreenScale;

/**
 Reduce image to fit in the provided size.
 The aspect ratio is kept.
 
 @discussion This method use less memory than `+ [reduceImage:toFitInSize:useMainScreenScale:]`.

 @param imageData The image data.
 @param size Size to fit in.
 @return Resized image or nil if the data is not interpreted.
 */
+ (UIImage*)resizeImageWithData:(NSData*)imageData toFitInSize:(CGSize)size;

/**
 Resize image to a provided size.
 
 @param image the image to modify.
 @param size the new size.
 @return resized image.
 */
+ (UIImage*)resizeImage:(UIImage *)image toSize:(CGSize)size;

/**
 Resize image with rounded corners to a provided size.
 
 @param image the image to modify.
 @param size the new size.
 @return resized image.
 */
+ (UIImage*)resizeImageWithRoundedCorners:(UIImage *)image toSize:(CGSize)size;

/**
 Paint an image with a color.
 
 @discussion
 All non fully transparent (alpha = 0) will be painted with the provided color.
 
 @param image the image to paint.
 @param color the color to use.
 @result a new UIImage object.
 */
+ (UIImage*)paintImage:(UIImage*)image withColor:(UIColor*)color;

/**
 Convert a rotation angle to the most suitable image orientation.
 
 @param angle rotation angle in degree.
 @return image orientation.
 */
+ (UIImageOrientation)imageOrientationForRotationAngleInDegree:(NSInteger)angle;

/**
 Draw the image resource in a view and transforms it to a pattern color.
 The view size is defined by patternSize and will have a "backgroundColor" backgroundColor.
 The resource image is drawn with the resourceSize size and is centered into its parent view.
 
 @param reourceName the image resource name.
 @param backgroundColor the pattern background color.
 @param patternSize the pattern size.
 @param resourceSize the resource size in the pattern.
 @return the pattern color which can be used to define the background color of a view in order to display the provided image as its background.
 */
+ (UIColor*)convertImageToPatternColor:(NSString*)reourceName backgroundColor:(UIColor*)backgroundColor patternSize:(CGSize)patternSize resourceSize:(CGSize)resourceSize;

#pragma mark - Video conversion
/**
Creates a `UIAlertController` with appropriate `AVAssetExportPreset` choices for the video passed in.
 @param videoAsset The video to generate the choices for.
 @param completion The block called when a preset has been chosen. `presetName` will contain the preset name or `nil` if cancelled.
*/
+ (UIAlertController*)videoConversionPromptForVideoAsset:(AVAsset *)videoAsset
                                           withCompletion:(void (^)(NSString * _Nullable presetName))completion;

#pragma mark - App permissions

/**
 Check permission to access a media.
 
@discussion
 If the access was not yet granted, a dialog will be shown to the user.
 If it is the first attempt to access the media, the dialog is the classic iOS one.
 Else, the dialog will ask the user to manually change the permission in the app settings.

 @param mediaType the media type, either AVMediaTypeVideo or AVMediaTypeAudio.
 @param manualChangeMessage the message to display if the end user must change the app settings manually.
 @param viewController the view controller to attach the dialog displaying manualChangeMessage.
 @param handler the block called with the result of requesting access
 */
+ (void)checkAccessForMediaType:(NSString *)mediaType
            manualChangeMessage:(NSString*)manualChangeMessage
      showPopUpInViewController:(UIViewController*)viewController
              completionHandler:(void (^)(BOOL granted))handler;

/**
 Check required permission for the provided call.

 @param isVideoCall flag set to YES in case of video call.
 @param manualChangeMessageForAudio the message to display if the end user must change the app settings manually for audio.
 @param manualChangeMessageForVideo the message to display if the end user must change the app settings manually for video
 @param viewController the view controller to attach the dialog displaying manualChangeMessage.
 @param handler the block called with the result of requesting access
 */
+ (void)checkAccessForCall:(BOOL)isVideoCall
manualChangeMessageForAudio:(NSString*)manualChangeMessageForAudio
manualChangeMessageForVideo:(NSString*)manualChangeMessageForVideo
 showPopUpInViewController:(UIViewController*)viewController
         completionHandler:(void (^)(BOOL granted))handler;

/**
 Check permission to access Contacts.

 @discussion
 If the access was not yet granted, a dialog will be shown to the user.
 If it is the first attempt to access the media, the dialog is the classic iOS one.
 Else, the dialog will ask the user to manually change the permission in the app settings.

 @param manualChangeMessage the message to display if the end user must change the app settings manually.
                            If nil, the dialog for displaying manualChangeMessage will not be shown.
 @param viewController the view controller to attach the dialog displaying manualChangeMessage.
 @param handler the block called with the result of requesting access
 */
+ (void)checkAccessForContacts:(NSString*)manualChangeMessage
     showPopUpInViewController:(UIViewController*)viewController
             completionHandler:(void (^)(BOOL granted))handler;

/**
 Check permission to access Contacts.

 @discussion
 If the access was not yet granted, a dialog will be shown to the user.
 If it is the first attempt to access the media, the dialog is the classic iOS one.
 Else, the dialog will ask the user to manually change the permission in the app settings.

 @param manualChangeTitle the title to display if the end user must change the app settings manually.
 @param manualChangeMessage the message to display if the end user must change the app settings manually.
                            If nil, the dialog for displaying manualChangeMessage will not be shown.
 @param viewController the view controller to attach the dialog displaying manualChangeMessage.
 @param handler the block called with the result of requesting access
 */
+ (void)checkAccessForContacts:(NSString *)manualChangeTitle
       withManualChangeMessage:(NSString *)manualChangeMessage
     showPopUpInViewController:(UIViewController *)viewController
             completionHandler:(void (^)(BOOL granted))handler;

#pragma mark - HTML processing

/**
 Removing DTCoreText artifacts:
 - Trim trailing whitespace and newlines in the string content.
 - Replace DTImageTextAttachments with a simple NSTextAttachment subclass.
 
 @param mutableAttributedString a mutable attributed string.
 */
+ (void)removeDTCoreTextArtifacts:(NSMutableAttributedString*)mutableAttributedString;

/**
 Make some matrix identifiers clickable in the string content.
 
 @param mutableAttributedString a mutable attributed string.
 @param enabledMatrixIdsBitMask the bitmask used to list the types of matrix id to process (see MXKTOOLS_XXX__BITWISE).
 */
+ (void)createLinksInMutableAttributedString:(NSMutableAttributedString*)mutableAttributedString forEnabledMatrixIds:(NSInteger)enabledMatrixIdsBitMask;

#pragma mark - HTML processing - blockquote display handling

/**
 Return a CSS to make DTCoreText mark blockquote blocks in the `NSAttributedString` output.

 These blocks  output will have a `DTTextBlocksAttribute` attribute in the `NSAttributedString`
 that can be used for later computation (in `removeMarkedBlockquotesArtifacts`).

 @return a CSS string.
 */
+ (NSString*)cssToMarkBlockquotes;

/**
 Removing DTCoreText artifacts used to mark blockquote blocks.

 @param mutableAttributedString a mutable attributed string.
 */
+ (void)removeMarkedBlockquotesArtifacts:(NSMutableAttributedString*)mutableAttributedString;

/**
 Enumerate all sections of the attributed string that refer to an HTML blockquote block.

 Must be used with `cssToMarkBlockquotes` and `removeMarkedBlockquotesArtifacts`.

 @param attributedString the attributed string.
 @param block a block called for each HTML blockquote blocks.
 */
+ (void)enumerateMarkedBlockquotesInAttributedString:(NSAttributedString*)attributedString usingBlock:(void (^)(NSRange range, BOOL *stop))block;

#pragma mark - Push

/**
 Trim push token in order to log it.

 @param pushToken the token to trim.
 @return a trimmed description.
 */
+ (NSString*)logForPushToken:(NSData*)pushToken;

@end
