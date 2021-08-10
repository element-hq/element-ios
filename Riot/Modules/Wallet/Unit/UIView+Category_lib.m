//
//  UIView+Category_lib.m
//  UniversalApp
//
//  Created by 廖燊 on 2021/5/29.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "UIView+Category_lib.h"
#import <objc/runtime.h>

static char *UIViewYXTapActionHandlerKey="UIViewTapActionHandlerKey";
static char *UIViewYXLongPressActionHandlerKey="UIViewLongPressActionHandlerKey";
@implementation UIView (Category_lib)
#pragma mark - 手势
// 添加单击手势
- (void)mm_addTapGestureWithTarget:(id)target action:(SEL)action
{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:tapGesture];
}

// 添加滑动手势
- (void)mm_addPanGestureWithTarget:(id)target action:(SEL)action
{
    self.userInteractionEnabled = YES;
    UIPanGestureRecognizer *tapGesture = [[UIPanGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:tapGesture];
}

- (void)addTapAction:(void (^)(UITapGestureRecognizer *))handler {
    self.userInteractionEnabled = YES;
    objc_setAssociatedObject(self, UIViewYXTapActionHandlerKey, handler, OBJC_ASSOCIATION_COPY);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(x_tapAction:)];
    [self addGestureRecognizer:tap];
}

- (void)addLongPressAction:(void (^)(UILongPressGestureRecognizer *))handler {
    self.userInteractionEnabled = YES;
    objc_setAssociatedObject(self, UIViewYXLongPressActionHandlerKey, handler, OBJC_ASSOCIATION_COPY);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(x_longPressAction:)];
    [self addGestureRecognizer:lp];
}

- (void)x_tapAction:(UITapGestureRecognizer *)sender {
    void(^handler)(UITapGestureRecognizer *)=objc_getAssociatedObject(self, UIViewYXTapActionHandlerKey);
    if(handler) {
        handler(sender);
    }
}

- (void)x_longPressAction:(UILongPressGestureRecognizer *)sender {
    void(^handler)(UILongPressGestureRecognizer *)=objc_getAssociatedObject(self, UIViewYXLongPressActionHandlerKey);
    if(handler) {
        handler(sender);
    }
}
@end
