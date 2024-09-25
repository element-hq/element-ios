/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class TableViewCellWithCheckBoxes;

/**
 `TableViewCellWithCheckBoxes` delegate.
 */
@protocol TableViewCellWithCheckBoxesDelegate <NSObject>

/**
 Tells the delegate that the user taps on a check box.
 
 @param tableViewCellWithCheckBoxes the `TableViewCellWithCheckBoxes` instance.
 @param index the index of the concerned check box.
 */
- (void)tableViewCellWithCheckBoxes:(TableViewCellWithCheckBoxes *)tableViewCellWithCheckBoxes didTapOnCheckBoxAtIndex:(NSUInteger)index;

@end

/**
 'TableViewCellWithCheckBoxes' inherits 'MXKTableViewCell' class.
 It displays several options in a UITableViewCell. Each option has its own check box and its label.
 All option have the same width and they are horizontally aligned inside the main container.
 They are vertically centered.
 */
@interface TableViewCellWithCheckBoxes : MXKTableViewCell

@property (weak, nonatomic) IBOutlet UIView *mainContainer;

/**
 The number of boxes
 */
@property (nonatomic) NSUInteger checkBoxesNumber;

/**
 The current array of checkBoxes
 */
@property (nonatomic, readonly) NSArray<UIImageView*> *checkBoxes;

/**
 The current array of labels
 */
@property (nonatomic, readonly) NSArray<UILabel*> *labels;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainContainerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainContainerTrailingConstraint;

/**
 The delegate for the cell.
 */
@property (nonatomic, weak) id<TableViewCellWithCheckBoxesDelegate> delegate;

/**
 Default is NO. Controls whether multiple check boxes can be selected simultaneously
 */
@property (nonatomic) BOOL allowsMultipleSelection;

/**
 Select or unselect a check box.
 If multiple selection is not allowed, this method unselect the current selected box in case of a new selection.
 
 @param isSelected the new value of the check box.
 @param index the index of the check box.
 */
- (void)setCheckBoxValue:(BOOL)isSelected atIndex:(NSUInteger)index;

/**
 Get the current state of a check box
 */
- (BOOL)checkBoxValueAtIndex:(NSUInteger)index;

@end
