//
//  SCEventProxy.h
//  Test
//
//  Created by ty.Chen on 2019/12/27.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCEventProxyProtocol.h"

@interface SCEventProxy : NSObject <SCEventProxyProtocol>

@property (nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *eventStrategy;

- (NSInvocation *)createInvocationForSelector:(SEL)selector;

@end
