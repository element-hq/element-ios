//
//  SCEventProxy.m
//  Test
//
//  Created by ty.Chen on 2019/12/27.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "SCEventProxy.h"
#import "NSInvocation+SCWrap.h"

@implementation SCEventProxy

- (void)handleEventProxyForEvent:(NSString *)eventName paramaters:(NSArray *)paramaters {
    [self handleEventProxyForEvent:eventName paramaters:paramaters needWrap:YES];
}

- (void)handleEventProxyForEvent:(NSString *)eventName paramaters:(NSArray *)paramaters needWrap:(BOOL)needWrap {
    NSInvocation *invocation = [self.eventStrategy valueForKey:eventName];
    if (invocation.methodSignature.numberOfArguments - 2 != paramaters.count && paramaters) {
        NSAssert(invocation.methodSignature.numberOfArguments - 2 == paramaters.count, @"参数个数不匹配");
        return;
    }
    [invocation sc_wrapAndSetArguments:paramaters needWrap:needWrap];
    [invocation invoke];
}

- (NSInvocation *)createInvocationForSelector:(SEL)selector {
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
    if (!methodSignature) {
        NSString *errorTip = [NSString stringWithFormat:@"`%@`类的`%@`方法签名不存在", NSStringFromClass(self.class), NSStringFromSelector(selector)];
        NSAssert(methodSignature, errorTip);
        return nil;
    }
    NSInvocation *invocation = [NSInvocation
                                invocationWithMethodSignature:methodSignature];
    invocation.target = self;
    invocation.selector = selector;
    return invocation;
}

@end
