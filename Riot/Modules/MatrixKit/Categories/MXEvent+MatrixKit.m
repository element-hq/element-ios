/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXEvent+MatrixKit.h"
#import <objc/runtime.h>

@implementation MXEvent (MatrixKit)

- (MXKEventFormatterError)mxkEventFormatterError
{
    NSNumber *associatedError = objc_getAssociatedObject(self, @selector(mxkEventFormatterError));
    if (associatedError)
    {
        return [associatedError unsignedIntegerValue];
    }
    return MXKEventFormatterErrorNone;
}

- (void)setMxkEventFormatterError:(MXKEventFormatterError)mxkEventFormatterError
{
    objc_setAssociatedObject(self, @selector(mxkEventFormatterError), [NSNumber numberWithUnsignedInteger:mxkEventFormatterError], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mxkIsHighlighted
{
    NSNumber *associatedIsHighlighted = objc_getAssociatedObject(self, @selector(mxkIsHighlighted));
    if (associatedIsHighlighted)
    {
        return [associatedIsHighlighted boolValue];
    }
    return NO;
}

- (void)setMxkIsHighlighted:(BOOL)mxkIsHighlighted
{
    objc_setAssociatedObject(self, @selector(mxkIsHighlighted), [NSNumber numberWithBool:mxkIsHighlighted], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
