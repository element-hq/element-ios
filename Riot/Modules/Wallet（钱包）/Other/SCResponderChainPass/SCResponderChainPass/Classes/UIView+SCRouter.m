//
//  UIView+SCRouter.m
//  Test
//
//  Created by ty.Chen on 2019/12/27.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "UIView+SCRouter.h"
#import "UIResponder+SCRouter.h"
#import <objc/runtime.h>

const void *kEventProxyUIViewKey = "kEventProxyUIViewKey";


@implementation UIView (SCRouter)

- (void)routerEventForName:(NSString *)eventName paramaters:(NSArray *)paramaters {
    if (self.eventProxy) {
        [self.eventProxy handleEventProxyForEvent:eventName paramaters:paramaters];
    } else {
        [super routerEventForName:eventName paramaters:paramaters];
    }
}

#pragma mark - Setter

- (void)setEventProxy:(id<SCEventProxyProtocol>)eventProxy {
    objc_setAssociatedObject(self, kEventProxyUIViewKey, eventProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Getter

- (id<SCEventProxyProtocol>)eventProxy {
    return objc_getAssociatedObject(self, kEventProxyUIViewKey);
}

@end
