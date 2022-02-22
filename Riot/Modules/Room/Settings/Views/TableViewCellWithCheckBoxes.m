/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "TableViewCellWithCheckBoxes.h"

#import "GeneratedInterface-Swift.h"

// The space between 2 check boxes
#define TABLEVIEWCELLWITHCHECKBOXES_MARGIN 8

@interface TableViewCellWithCheckBoxes ()
{
    NSMutableArray *checkBoxesArray;
    NSMutableArray *labelArray;
}
@end

@implementation TableViewCellWithCheckBoxes

- (void)setCheckBoxesNumber:(NSUInteger)checkBoxesNumber
{
    if (_checkBoxesNumber == checkBoxesNumber)
    {
        return;
    }
    
    // Remove existing items
    NSArray *subviews = self.mainContainer.subviews;
    for (UIView *view in subviews)
    {
        [view removeFromSuperview];
    }
    
    _checkBoxesNumber = checkBoxesNumber;
    
    if (!_checkBoxesNumber)
    {
        // Nothing to do
        return;
    }
    
    checkBoxesArray = [NSMutableArray arrayWithCapacity:checkBoxesNumber];
    labelArray = [NSMutableArray arrayWithCapacity:checkBoxesNumber];
    
    CGFloat containerWidth = (self.mainContainer.frame.size.width - ((checkBoxesNumber - 1.0) * TABLEVIEWCELLWITHCHECKBOXES_MARGIN)) / checkBoxesNumber;
    
    UIView *previousContainer = nil;
    NSLayoutConstraint *topConstraint, *leftConstraint, *bottomConstraint;
    NSLayoutConstraint *widthConstraint, *heightConstraint, *centerYConstraint, *centerXConstraint;
    
    for (NSInteger index = 0; index < checkBoxesNumber; index++)
    {
        UIView *checkboxContainer = [[UIView alloc] initWithFrame:CGRectMake(index * (containerWidth + TABLEVIEWCELLWITHCHECKBOXES_MARGIN), 0, containerWidth, self.mainContainer.frame.size.height)];
        checkboxContainer.backgroundColor = [UIColor clearColor];
        [self.mainContainer addSubview:checkboxContainer];
        
        // Add container constraints
        checkboxContainer.translatesAutoresizingMaskIntoConstraints = NO;
        if (!previousContainer)
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.mainContainer
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:0];
            widthConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.mainContainer
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:(1.0 / checkBoxesNumber)
                                                            constant:(- ((checkBoxesNumber - 1.0) * TABLEVIEWCELLWITHCHECKBOXES_MARGIN) / checkBoxesNumber)];
        }
        else
        {
            leftConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:previousContainer
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:TABLEVIEWCELLWITHCHECKBOXES_MARGIN];
            widthConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:previousContainer
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1
                                                            constant:0];
        }
        
        topConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.mainContainer
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1
                                                         constant:0];
        
        bottomConstraint = [NSLayoutConstraint constraintWithItem:checkboxContainer
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.mainContainer
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, topConstraint, bottomConstraint]];
        
        previousContainer = checkboxContainer;
        
        // Add Checkbox and Label
        UIImageView *checkbox = [[UIImageView alloc] initWithFrame:CGRectMake(14, 11, 22, 22)];
        checkbox.translatesAutoresizingMaskIntoConstraints = NO;
        [checkboxContainer addSubview:checkbox];
        
        // Store the new check box unselected by default
        checkbox.image = AssetImages.selectionUntick.image;
        checkbox.tintColor = ThemeService.shared.theme.tintColor;
        checkbox.tag = 0;
        [checkBoxesArray addObject:checkbox];
        
        UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, containerWidth - 60, 31)];
        theLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [checkboxContainer addSubview:theLabel];
        [labelArray addObject:theLabel];
        
        UIView *checkboxMask = [[UIView alloc] initWithFrame:CGRectMake(7, 4, 36, 36)];
        checkboxMask.translatesAutoresizingMaskIntoConstraints = NO;
        [checkboxContainer addSubview:checkboxMask];
        // Listen to check box tap
        checkboxMask.tag = index;
        checkboxMask.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCheckBoxTap:)];
        [tapGesture setNumberOfTouchesRequired:1];
        [tapGesture setNumberOfTapsRequired:1];
        [tapGesture setDelegate:self];
        [checkboxMask addGestureRecognizer:tapGesture];
        
        // Add switch constraints
        leftConstraint = [NSLayoutConstraint constraintWithItem:checkbox
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:checkboxContainer
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:14];
        
        widthConstraint = [NSLayoutConstraint constraintWithItem:checkbox
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1
                                                        constant:22];
        
        centerYConstraint = [NSLayoutConstraint constraintWithItem:checkbox
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:checkboxContainer
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, centerYConstraint]];
        
        
        // Add Label constraints
        topConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:checkboxContainer
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0];
        
        leftConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                      attribute:NSLayoutAttributeLeading
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:checkbox
                                                      attribute:NSLayoutAttributeTrailing
                                                     multiplier:1
                                                       constant:9];
        
        centerYConstraint = [NSLayoutConstraint constraintWithItem:theLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:checkboxContainer
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, centerYConstraint]];
        
        // Add check box mask constraints
        widthConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1
                                                        constant:36];
        
        heightConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1
                                                        constant:36];
        
        centerXConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:checkbox
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1
                                                          constant:0.0f];
        
        centerYConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:checkbox
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]];
    }
}

- (NSArray*)checkBoxes
{
    return [NSArray arrayWithArray:checkBoxesArray];
}

- (NSArray*)labels
{
    return [NSArray arrayWithArray:labelArray];
}

- (void)setCheckBoxValue:(BOOL)isSelected atIndex:(NSUInteger)index
{
    if (index < checkBoxesArray.count)
    {
        UIImageView *checkBox = checkBoxesArray[index];
        
        if (isSelected && !checkBox.tag)
        {
            checkBox.image = AssetImages.selectionTick.image;
            checkBox.tag = 1;
            
            if (!self.allowsMultipleSelection)
            {
                // Unselect others check boxes
                for (NSUInteger k = 0; k < checkBoxesArray.count; k++)
                {
                    if (k != index)
                    {
                        checkBox = checkBoxesArray[k];
                        if (checkBox.tag)
                        {
                            checkBox.image = AssetImages.selectionUntick.image;
                            checkBox.tag = 0;
                        }
                    }
                }
            }
        }
        else if (!isSelected && checkBox.tag)
        {
            checkBox.image = AssetImages.selectionUntick.image;
            checkBox.tag = 0;
        }
    }
}

- (BOOL)checkBoxValueAtIndex:(NSUInteger)index
{
    if (index < checkBoxesArray.count)
    {
        UIImageView *checkBox = checkBoxesArray[index];
        
        return ((BOOL)checkBox.tag);
    }
    
    return NO;
}

#pragma mark - Action

- (IBAction)onCheckBoxTap:(UITapGestureRecognizer*)sender
{
    if (_delegate)
    {
        [_delegate tableViewCellWithCheckBoxes:self didTapOnCheckBoxAtIndex:sender.view.tag];
    }
}
@end

