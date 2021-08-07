//
//  UIResponder+SCRouter.h
//  SCResponderChain
//
//  Created by samueler on 2019/2/12.
//  Copyright © 2019 samueler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (SCRouter)

- (void)routerEventForName:(NSString *)eventName paramater:(id)paramater;

- (void)routerEventForName:(NSString *)eventName paramaters:(NSArray *)paramaters;

@end
