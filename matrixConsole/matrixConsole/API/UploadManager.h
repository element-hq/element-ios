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

#import <UIKit/UIKit.h>

@interface UploadManager : NSObject

// trigger the kMediaUploadProgressNotification notification from the upload parameters
// URL : the uploading media URL
// bytesWritten / totalBytesWritten / totalBytesExpectedToWrite : theses parameters are provided by NSURLConnectionDelegate
// initialRange / range: the current upload info could be a subpart of uploads. initialRange defines the global upload progress already did done before this current upload.
// range is the range value of this upload in the global scope.
// e.g. : Upload a media can be split in two parts :
// 1 - upload the thumbnail -> initialRange = 0, range = 0.1 : assume that the thumbnail upload is 10% of the upload process
// 2 - upload the media -> initialRange = 0,1, range = 0.9 : the media upload is 90% of the global upload
+ (void) onUploadProgress:(NSString*)URL bytesWritten:(NSUInteger)bytesWritten  totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite  initialRange:(CGFloat)initialRange  range:(CGFloat)range;

// returns the stats info with kMediaLoaderProgress... key
+ (NSDictionary*)statsInfoForURL:(NSString*)URL;

// the upload
+ (void)removeURL:(NSString*)URL;

@end
