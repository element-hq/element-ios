/*
 Copyright 2019 New Vector Ltd
 
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

#import "UITextView+MatrixKit.h"

@implementation UITextView(MatrixKit)

- (BOOL)isThereALinkNearPoint:(CGPoint)point
{
    if (!CGRectContainsPoint(self.bounds, point))
    {
        return NO;
    }
    
    UITextPosition *textPosition = [self closestPositionToPoint:point];
    
    if (!textPosition)
    {
        return NO;
    }
    
    UITextRange *textRange = [self.tokenizer rangeEnclosingPosition:textPosition
                                                    withGranularity:UITextGranularityCharacter
                                                        inDirection:UITextLayoutDirectionLeft];
    
    if (!textRange)
    {
        return NO;
    }
    
    NSInteger startIndex = [self offsetFromPosition:self.beginningOfDocument toPosition:textRange.start];
    
    if (startIndex < 0)
    {
        return NO;
    }
    
    return [self.attributedText attribute:NSLinkAttributeName atIndex:startIndex effectiveRange:NULL] != nil;
}

@end
