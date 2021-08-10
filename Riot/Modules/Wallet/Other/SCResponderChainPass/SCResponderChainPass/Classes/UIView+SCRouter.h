//
//  UIView+SCRouter.h
//  Test
//
//  Created by ty.Chen on 2019/12/27.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCEventProxyProtocol.h"

@interface UIView (SCRouter)

@property (nonatomic, strong) id<SCEventProxyProtocol> eventProxy;

@end
