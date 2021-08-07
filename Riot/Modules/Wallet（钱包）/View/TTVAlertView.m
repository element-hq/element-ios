//
//  TTVAlertView.m
//  TouchTV
//
//  Created by rhc on 16/9/13.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import "TTVAlertView.h"

const char *EB_AlertView_Block = "EB_AlertView_Block";

@interface UIAlertView(TTVAlertView)
- (void)setClickBlock:(ClickAtIndexBlock)block;
- (ClickAtIndexBlock)clickBlock;
@end

@implementation UIAlertView(TTVAlertView)
- (void)setClickBlock:(ClickAtIndexBlock)block {
    objc_setAssociatedObject(self, EB_AlertView_Block, block, OBJC_ASSOCIATION_COPY);
}
- (ClickAtIndexBlock)clickBlock {
    return objc_getAssociatedObject(self, EB_AlertView_Block);
}

@end


@implementation TTVAlertView

+ (UIAlertView *)initWithTitle:(NSString*)title message:(NSString *)messge
             cancleButtonTitle:(NSString *)cancleButtonTitle
             OtherButtonsArray:(NSArray*)otherButtons
                  clickAtIndex:(ClickAtIndexBlock) clickAtIndex {
    
    UIAlertView  *al = [[UIAlertView alloc] initWithTitle:title message:messge delegate:self cancelButtonTitle:cancleButtonTitle otherButtonTitles: nil];
    al.clickBlock = clickAtIndex;
    for (NSString *otherTitle in otherButtons) {
        [al addButtonWithTitle:otherTitle];
    }
    [al show];
    
    return al;
}

#pragma mark   UIAlertViewDelegate
+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.clickBlock) {
        alertView.clickBlock(buttonIndex);
    }
}


+ (void)test {
    [TTVAlertView initWithTitle:nil message:@"Hello World!" cancleButtonTitle:@"Cancel" OtherButtonsArray:@[@"OK"] clickAtIndex:^(NSInteger buttonAtIndex) {
        NSLog(@"click index ====%ld",(long)buttonAtIndex);
    }];
}


@end
