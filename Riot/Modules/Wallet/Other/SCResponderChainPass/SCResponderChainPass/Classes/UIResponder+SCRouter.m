//
//  UIResponder+SCRouter.m
//  SCResponderChain
//
//  Created by samueler on 2019/2/12.
//  Copyright © 2019 samueler. All rights reserved.
//

#import "UIResponder+SCRouter.h"

@implementation UIResponder (SCRouter)
- (void)routerEventForEventName:(NSString *)eventName objc:(id)objc {
    if (!objc) {
        [[self nextResponder] routerEventForEventName:eventName objc:nil];
    } else {
        [self routerEventForEventName:eventName objcs:@[objc]];
    }
}

- (void)routerEventForEventName:(NSString *)eventName objcs:(NSArray *)objcs {
    [[self nextResponder] routerEventForEventName:eventName objcs:objcs];
}

- (void)routerEventForName:(NSString *)eventName paramater:(id)paramater {
    if (paramater) {
        [self routerEventForName:eventName paramaters:@[paramater]];
    } else {
        [self routerEventForName:eventName paramaters:nil];
    }
}

- (void)routerEventForName:(NSString *)eventName paramaters:(NSArray *)paramaters {
    [[self nextResponder] routerEventForName:eventName paramaters:paramaters];
}

@end
