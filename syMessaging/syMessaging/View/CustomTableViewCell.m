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

#import "CustomTableViewCell.h"
#import "MediaManager.h"

@interface CustomTableViewCell () {
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
}
@end

@implementation CustomTableViewCell

- (void)setPictureURL:(NSString *)pictureURL {
    // Cancel current request (if any)
    [downloadConnection cancel];
    downloadConnection = nil;
    downloadData = nil;
    
    _pictureURL = pictureURL;
    
    // Update user picture
    _pictureView.image = nil;
    if (pictureURL) {
        // Check cache
        _pictureView.image = [MediaManager loadCachePicture:pictureURL];
        
        if (!_pictureView.image) {
            if (_placeholder) {
                // Set picture placeholder
                _pictureView.image = [UIImage imageNamed:_placeholder];
            }
            
            // Download picture
            NSURL *url = [NSURL URLWithString:pictureURL];
            downloadData = [[NSMutableData alloc] init];
            downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
        }        
    } else {
        if (_placeholder) {
            // Set picture placeholder
            _pictureView.image = [UIImage imageNamed:_placeholder];
        }
    }
}

- (void)dealloc
{
    downloadData = nil;
    downloadConnection = nil;
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR: picture download failed: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append data
    [downloadData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Set the downloaded image
    _pictureView.image = [UIImage imageWithData:downloadData];
    if (_pictureView.image) {
        // Cache the downloaded data
        [MediaManager cachePictureWithData:downloadData forURL:_pictureURL];
    } else {
        if (_placeholder) {
            // Set picture placeholder
            _pictureView.image = [UIImage imageNamed:_placeholder];
        }
    }
    
    downloadData = nil;
    downloadConnection = nil;
}

@end