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

#import "MXCGrowingTextView.h"

@implementation MXCGrowingTextView

// override theses two methods to fix a weird IOS 8 issue
// it seems that the textview must be a little smaller than its superview
// else when MaxHeght is reached, the text scrolls up because setContentSize is called
// 1 - with a wrong contentSize < frame height so scroll to the top
// 2 - with the right content : resetScrollPositionForIOS7 fix the content Offset
// so center the textView in its superView

-(void)resizeTextView:(NSInteger)newSizeH {
    if ([delegate respondsToSelector:@selector(growingTextView:willChangeHeight:)]) {
        [delegate growingTextView:self willChangeHeight:newSizeH + self.layer.cornerRadius];
    }
    
    CGRect internalTextViewFrame = self.frame;
    internalTextViewFrame.size.height = newSizeH + self.layer.cornerRadius; // + padding
    self.frame = internalTextViewFrame;
    
    internalTextViewFrame.size.height = newSizeH - self.layer.cornerRadius;
    
    internalTextViewFrame.origin.y = contentInset.top - contentInset.bottom;
    internalTextViewFrame.origin.x = contentInset.left;
    
    if(!CGRectEqualToRect(self.internalTextView.frame, internalTextViewFrame)) {
        self.internalTextView.frame = internalTextViewFrame;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect r = self.bounds;
    r.origin.y = 0;
    r.origin.x = contentInset.left;
    r.size.width -= contentInset.left + contentInset.right;
    
    if (self.hasText) {
        r.origin.y += self.layer.cornerRadius / 2;
        r.size.height -= self.layer.cornerRadius;
    }
    
    if (!CGRectEqualToRect(r,  self.internalTextView.frame )) {
        self.internalTextView.frame = r;
    }
}

@end
