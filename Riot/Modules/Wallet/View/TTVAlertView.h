//
//  TTVAlertView.h
//  TouchTV
//
//  Created by rhc on 16/9/13.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ClickAtIndexBlock)(NSInteger buttonIndex);

@interface TTVAlertView : NSObject

+ (UIAlertView *)initWithTitle:(NSString*)title message:(NSString *)messge
             cancleButtonTitle:(NSString *)cancleButtonTitle
             OtherButtonsArray:(NSArray*)otherButtons
                  clickAtIndex:(ClickAtIndexBlock) clickAtIndex;

+ (void)test ;

@end
