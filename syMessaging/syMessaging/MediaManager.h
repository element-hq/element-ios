/*
 Copyright 2014 OpenMarket Ltd
 
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

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

// The callback blocks
typedef void (^blockMediaManager_onImageReady)(UIImage *image);
typedef void (^blockMediaManager_onError)(NSError *error);

@interface MediaManager : NSObject

+ (id)sharedInstance;

// Load a picture from the local cache or download it if it is not available yet.
// In this second case a mediaLoader reference is returned in order to let the user cancel this action.
+ (id)loadPicture:(NSString*)pictureURL
            success:(blockMediaManager_onImageReady)success
            failure:(blockMediaManager_onError)failure;
+ (void)cancel:(id)mediaLoader;

+ (NSString*)cachePictureWithData:(NSData*)imageData forURL:(NSString *)pictureURL;

+ (void)clearCache;

@end
