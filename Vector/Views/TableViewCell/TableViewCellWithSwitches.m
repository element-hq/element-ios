/*
 Copyright 2016 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TableViewCellWithSwitches.h"

// The space between 2 switches
#define TABLEVIEWCELLWITHSWITCHES_MARGIN 8

@interface TableViewCellWithSwitches ()
{
    NSMutableArray *switchArray;
    NSMutableArray *labelArray;
}
@end

@implementation TableViewCellWithSwitches

- (void)setSwitchesNumber:(NSUInteger)switchesNumber
{
    if (_switchesNumber == switchesNumber)
    {
        return;
    }
    
    // Remove existing items
    NSArray *subviews = self.mainContainer.subviews;
    for (UIView *view in subviews)
    {
        [view removeFromSuperview];
    }
    
    _switchesNumber = switchesNumber;
    
    if (!switchesNumber)
    {
        // Nothing to do
        return;
    }
    
    switchArray = [NSMutableArray arrayWithCapacity:switchesNumber];
    labelArray = [NSMutableArray arrayWithCapacity:switchesNumber];
    
    CGFloat containerWidth = (self.mainContainer.frame.size.width - ((switchesNumber - 1.0) * TABLEVIEWCELLWITHSWITCHES_MARGIN)) / switchesNumber;
    
    UIView *previousContainer = nil;
    NSLayoutConstraint *topConstraint, *leftConstraint, *bottomConstraint;
    NSLayoutConstraint *widthConstraint, *centerYConstraint;
    
    for (NSInteger index = 0; index < switchesNumber; index++)
    {
        UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(index * (containerWidth + TABLEVIEWCELLWITHSWITCHES_MARGIN), 0, containerWidth, self.mainContainer.frame.size.height)];
        switchContainer.backgroundColor = [UIColor clearColor];
        [self.mainContainer addSubview:switchContainer];
        
        // Add container constraints
        switchContainer.translatesAutoresizingMaskIntoConstraints = NO;
        if (!previousContainer)
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.mainContainer
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:0];
            widthConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.mainContainer
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:(1.0 / switchesNumber)
                                                            constant:(- ((switchesNumber - 1.0) * TABLEVIEWCELLWITHSWITCHES_MARGIN) / switchesNumber)];
        }
        else
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:previousContainer
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:TABLEVIEWCELLWITHSWITCHES_MARGIN];
            widthConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:previousContainer
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1
                                                            constant:0];
        }
        
        topConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.mainContainer
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1
                                                         constant:0];
        
        bottomConstraint = [NSLayoutConstraint constraintWithItem:switchContainer
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.mainContainer
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, topConstraint, bottomConstraint]];
        
        previousContainer = switchContainer;
        
        // Add Switch and Label
        UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51, 31)];
        theSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [switchContainer addSubview:theSwitch];
        [switchArray addObject:theSwitch];
        
        UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, containerWidth - 60, 31)];
        theLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [switchContainer addSubview:theLabel];
        [labelArray addObject:theLabel];
        
        // Add switch constraints
        leftConstraint = [NSLayoutConstraint constraintWithItem:theSwitch
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:switchContainer
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:0];
        
        widthConstraint = [NSLayoutConstraint constraintWithItem:theSwitch
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1
                                                        constant:51];
        
        centerYConstraint = [NSLayoutConstraint constraintWithItem:theSwitch
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:switchContainer
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, centerYConstraint]];
        
        
        // Add Label constraints
        topConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:switchContainer
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0];
        
        leftConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                      attribute:NSLayoutAttributeLeading
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:theSwitch
                                                      attribute:NSLayoutAttributeTrailing
                                                     multiplier:1
                                                       constant:9];
        
        centerYConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:switchContainer
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, centerYConstraint]];
    }
}

- (NSArray*)switches
{
    return [NSArray arrayWithArray:switchArray];
}

- (NSArray*)labels
{
    return [NSArray arrayWithArray:labelArray];
}

@end

