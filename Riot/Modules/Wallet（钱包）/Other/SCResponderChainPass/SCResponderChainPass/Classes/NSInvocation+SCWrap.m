//
//  NSInvocation+SCWrap.m
//  Pods-SCResponderChainPass_Example
//
//  Created by ty.Chen on 2020/1/7.
//

#import "NSInvocation+SCWrap.h"

@implementation NSInvocation (SCWrap)

- (void)sc_wrapAndSetArguments:(NSArray *)arguments needWrap:(BOOL)needWrap {
    for (NSInteger idx = 2; idx < self.methodSignature.numberOfArguments; idx++) {
        id paramater = arguments[idx - 2];
        char *argumentType = (char *)[self.methodSignature getArgumentTypeAtIndex:idx];
        if (needWrap) {
            if ([paramater isKindOfClass:[NSNumber class]]) {
                NSNumber *paramaterNumberObj = (NSNumber *)paramater;
                if (!strcmp(argumentType, @encode(char))) {
                    char value = paramaterNumberObj.charValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(unsigned char))) {
                    unsigned char value = paramaterNumberObj.unsignedCharValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(short))) {
                    short value = paramaterNumberObj.shortValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(unsigned short))) {
                    unsigned short value = paramaterNumberObj.unsignedShortValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(int))) {
                    int value = paramaterNumberObj.intValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(unsigned int))) {
                    unsigned int value = paramaterNumberObj.unsignedIntValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(long))) {
                    long value = paramaterNumberObj.longValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(unsigned long))) {
                    unsigned long value = paramaterNumberObj.unsignedLongValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(long long))) {
                    long long value = paramaterNumberObj.longLongValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(unsigned long long))) {
                    unsigned long long value = paramaterNumberObj.unsignedLongLongValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(float))) {
                    float value = paramaterNumberObj.floatValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(double))) {
                    double value = paramaterNumberObj.doubleValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(BOOL))) {
                    BOOL value = paramaterNumberObj.boolValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(NSInteger))) {
                    NSInteger value = paramaterNumberObj.integerValue;
                    [self setArgument:&value atIndex:idx];
                } else if (!strcmp(argumentType, @encode(NSUInteger))) {
                    NSUInteger value = paramaterNumberObj.unsignedIntegerValue;
                    [self setArgument:&value atIndex:idx];
                }
            } else if ([paramater isKindOfClass:[NSValue class]]) {
                NSValue *paramaterValueObj = (NSValue *)paramater;
                if (strcmp(argumentType, @encode(CGPoint)) == 0) {
                    CGPoint value = paramaterValueObj.CGPointValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(CGSize)) == 0) {
                    CGSize value = paramaterValueObj.CGSizeValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(CGRect)) == 0) {
                    CGRect value = paramaterValueObj.CGRectValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(CGVector)) == 0) {
                    CGVector value = paramaterValueObj.CGVectorValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(CGAffineTransform)) == 0) {
                    CGAffineTransform value = paramaterValueObj.CGAffineTransformValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(CATransform3D)) == 0) {
                    CATransform3D value = paramaterValueObj.CATransform3DValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(NSRange)) == 0) {
                    NSRange value = paramaterValueObj.rangeValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(UIOffset)) == 0) {
                    UIOffset value = paramaterValueObj.UIOffsetValue;
                    [self setArgument:&value atIndex:idx];
                } else if (strcmp(argumentType, @encode(UIEdgeInsets)) == 0) {
                    UIEdgeInsets value = paramaterValueObj.UIEdgeInsetsValue;
                    [self setArgument:&value atIndex:idx];
                } else {
                    [self setArgument:&paramaterValueObj atIndex:idx];
                }
            } else {
                [self setArgument:&paramater atIndex:idx];
            }
        } else {
            [self setArgument:&paramater atIndex:idx];
        }
    }
    
}

@end
