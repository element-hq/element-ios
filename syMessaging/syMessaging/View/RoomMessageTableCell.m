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

#import "RoomMessageTableCell.h"
#import "MediaManager.h"

@interface RoomMessageTableCell () {
    id attachmentLoader;
}
@end

@implementation RoomMessageTableCell

- (void)setAttachedImageURL:(NSString *)attachedImageURL {
    // Cancel media loader in progress (if any)
    if (attachmentLoader) {
        [MediaManager cancel:attachmentLoader];
        attachmentLoader = nil;
    }
    
    _attachedImageURL = attachedImageURL;
    
    // Reset image view
    _attachmentView.image = nil;
    // Consider provided url to update image view
    if (attachedImageURL) {
        // Load picture
        attachmentLoader = [MediaManager loadPicture:attachedImageURL
                                              success:^(UIImage *image) {
                                                  _attachmentView.image = image;
                                              }
                                              failure:^(NSError *error) {
                                                  NSLog(@"Failed to download attachment (%@): %@", _attachedImageURL, error);
                                              }];
    }
}

- (void)dealloc
{
    if (attachmentLoader) {
        [MediaManager cancel:attachmentLoader];
        attachmentLoader = nil;
    }
}

@end


@implementation IncomingMessageTableCell
@end


@implementation OutgoingMessageTableCell
@end