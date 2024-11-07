/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithButtons.h"

@interface MXKTableViewCellWithButtons ()
{
    NSMutableArray *buttonArray;
}
@end

@implementation MXKTableViewCellWithButtons

- (void)setMxkButtonNumber:(NSUInteger)buttonNumber
{
    if (_mxkButtonNumber == buttonNumber)
    {
        return;
    }
    
    _mxkButtonNumber = buttonNumber;
    buttonArray = [NSMutableArray arrayWithCapacity:buttonNumber];
    
    CGFloat containerWidth = self.contentView.frame.size.width / buttonNumber;
    UIView *previousContainer = nil;
    NSLayoutConstraint *leftConstraint;
    NSLayoutConstraint *rightConstraint;
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *topConstraint;
    NSLayoutConstraint *bottomConstraint;
    
    for (NSInteger index = 0; index < buttonNumber; index++)
    {
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(index * containerWidth, 0, containerWidth, self.contentView.frame.size.height)];
        buttonContainer.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:buttonContainer];
        
        // Add container constraints
        buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
        if (!previousContainer)
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.contentView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:0];
            widthConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.contentView
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:(1.0 / buttonNumber)
                                                            constant:0];
        }
        else
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:previousContainer
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:0];
            widthConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:previousContainer
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1
                                                            constant:0];
        }
        
        topConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.contentView
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1
                                                         constant:0];
        
        bottomConstraint = [NSLayoutConstraint constraintWithItem:buttonContainer
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0];

        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, topConstraint, bottomConstraint]];
        previousContainer = buttonContainer;
        
        // Add Button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10, 8, containerWidth - 20, buttonContainer.frame.size.height - 16);
        [buttonContainer addSubview:button];
        [buttonArray addObject:button];
        
        // Add button constraints
        button.translatesAutoresizingMaskIntoConstraints = NO;
        leftConstraint = [NSLayoutConstraint constraintWithItem:button
                                                      attribute:NSLayoutAttributeLeading
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:buttonContainer
                                                      attribute:NSLayoutAttributeLeading
                                                     multiplier:1
                                                       constant:10];
        rightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                      attribute:NSLayoutAttributeTrailing
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:buttonContainer
                                                      attribute:NSLayoutAttributeTrailing
                                                     multiplier:1
                                                       constant:-10];
        
        topConstraint = [NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:buttonContainer
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:8];
        
        bottomConstraint = [NSLayoutConstraint constraintWithItem:button
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:buttonContainer
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1
                                                         constant:-8];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    }
}

- (NSArray*)mxkButtons
{
    return [NSArray arrayWithArray:buttonArray];
}

@end

