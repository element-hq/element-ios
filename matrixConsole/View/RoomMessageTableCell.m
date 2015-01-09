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
#import "PieChartView.h"
#import "UploadManager.h"

@implementation RoomMessageTableCell

- (void)dealloc {
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateProgressUI:(NSDictionary*)downloadStatsDict {
    self.progressView.hidden = NO;
    
    NSString* downloadRate = [downloadStatsDict valueForKey:kMediaLoaderProgressDownloadRateKey];
    NSString* remaingTime = [downloadStatsDict valueForKey:kMediaLoaderProgressRemaingTimeKey];
    NSString* progressString = [downloadStatsDict valueForKey:kMediaLoaderProgressStringKey];
    
    NSMutableString* text = [[NSMutableString alloc] init];
    
    if (progressString) {
        [text appendString:progressString];
    }
    
    if (downloadRate) {
        [text appendFormat:@"\n%@", downloadRate];
    }
    
    if (remaingTime) {
        [text appendFormat:@"\n%@", remaingTime];
    }
    
    self.statsLabel.text = text;
    
    NSNumber* progressNumber = [downloadStatsDict valueForKey:kMediaLoaderProgressRateKey];
    
    if (progressNumber) {
        self.progressChartView.progress = progressNumber.floatValue;
    }
}

- (void)onMediaDownloadProgress:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:self.message.attachmentURL]) {
            [self updateProgressUI:notif.userInfo];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:self.message.attachmentURL]) {
            [self stopProgressUI];
            
            // the job is really over
            if ([notif.name isEqualToString:kMediaDownloadDidFinishNotification]) {
                // remove any pending observers
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
        }
    }
}

- (void)startProgressUI {
    
    BOOL isHidden = YES;
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // there is an attachment URL
    if (self.message.attachmentURL) {
        
        // check if there is a downlad in progress
        MediaLoader *loader = [MediaManager mediaLoaderForURL:self.message.attachmentURL];
        
        NSDictionary *dict = loader.downloadStatsDict;
        
        if (dict) {
            isHidden = NO;
            
            // defines the text to display
            [self updateProgressUI:dict];
        }
        
        // anyway listen to the progress event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadProgress:) name:kMediaDownloadProgressNotification object:nil];
    }
    
    self.progressView.hidden = isHidden;
}

- (void)stopProgressUI {
    self.progressView.hidden = YES;
    
    // do not remove the observer here
    // the download could restart without recomposing the cell
}

- (void)cancelDownload {
    // get the linked medida loader
    MediaLoader *loader = [MediaManager mediaLoaderForURL:self.message.attachmentURL];
    if (loader) {
        [loader cancel];
    }
    
    // ensure there is no more progress bar
    [self stopProgressUI];
}
@end


@implementation IncomingMessageTableCell
@end

@interface OutgoingMessageTableCell () {
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation OutgoingMessageTableCell

- (void)dealloc {
    [self stopAnimating];
}

-(void)startUploadAnimating {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaUploadProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadProgress:) name:kMediaUploadProgressNotification object:nil];
    
     self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    NSDictionary* uploadDict = [UploadManager statsInfoForURL:self.message.attachmentURL];
    
    if (uploadDict) {
        self.activityIndicator.hidden = YES;
        [self updateProgressUI:uploadDict];
    } else {
        self.activityIndicator.hidden = NO;
        self.progressView.hidden = YES;
    }
}


-(void)stopAnimating {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaUploadProgressNotification object:nil];
    [self.activityIndicator stopAnimating];
}

- (void)onUploadProgress:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:self.message.thumbnailURL] || [url isEqualToString:self.message.attachmentURL]) {
            self.activityIndicator.hidden = YES;
            [self updateProgressUI:notif.userInfo];
            
            // the upload is ended
            if (self.progressChartView.progress == 1.0) {
                self.progressView.hidden = YES;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // ensure that the text is still aligned to the left side of the screen
    // even during animation while enlarging/reducing the viewcontroller (with UISplitViewController)
    CGFloat leftInset = self.message.maxTextViewWidth -  self.message.contentSize.width;
    self.messageTextView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, -leftInset);
}
@end