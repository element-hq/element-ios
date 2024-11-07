/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKCellData.h"

@protocol MXKCellRenderingDelegate;

/**
 `MXKCellRendering` defines a protocol a view must conform to display a cell.

 A cell is a generic term. It can be a UITableViewCell or a UICollectionViewCell or any object
 expected by the end view controller.
 */
@protocol MXKCellRendering <NSObject>

/**
 *  Returns the `UINib` object initialized for the cell.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Configure the cell in order to display the passed data.
 
 The object implementing the `MXKCellRendering` protocol should be able to cast the past object
 into its original class.
 
 @param cellData the data object to render.
 */
- (void)render:(MXKCellData*)cellData;

/**
 Compute the height of the cell to display the passed data.
 
 @TODO: To support correctly the dynamic fonts, we have to remove this method and
 its use by enabling self sizing cells at the table view level.
 When we create a self-sizing table view cell, we need to set the property `estimatedRowHeight` of the table view
 and use constraints to define the cell’s size.
 
 @param cellData the data object to render.
 @param maxWidth the maximum available width.
 @return the cell height
 */
+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth;

@optional

/**
 User's actions delegate.
 */
@property (nonatomic, weak) id<MXKCellRenderingDelegate> delegate;

/**
 This optional getter allow to retrieve the data object currently rendered by the cell.
 
 @return the current rendered data object.
 */
- (MXKCellData*)renderedCellData;

/**
 Stop processes no more needed when cell is not visible.

 The cell is no more displayed but still recycled. This is time to stop animation.
 */
- (void)didEndDisplay;

@end

/**
`MXKCellRenderingDelegate` defines a protocol used when the user has interactions with
 the cell view.
 */
@protocol MXKCellRenderingDelegate <NSObject>

/**
 Tells the delegate that a user action (button pressed, tap, long press...) has been observed in the cell.

 The action is described by the `actionIdentifier` param.
 This identifier is specific and depends to the cell view class implementing MXKCellRendering.
 
 @param cell the cell in which gesture has been observed.
 @param actionIdentifier an identifier indicating the action type (tap, long press...) and which part of the cell is concerned.
 @param userInfo a dict containing additional information. It depends on actionIdentifier. May be nil.
 */
- (void)cell:(id<MXKCellRendering>)cell didRecognizeAction:(NSString*)actionIdentifier userInfo:(NSDictionary *)userInfo;

/**
 Asks the delegate if a user action (click on a link) can be done.

 The action is described by the `actionIdentifier` param.
 This identifier is specific and depends to the cell view class implementing MXKCellRendering.

 @param cell the cell in which gesture has been observed.
 @param actionIdentifier an identifier indicating the action type (link click) and which part of the cell is concerned.
 @param userInfo a dict containing additional information. It depends on actionIdentifier. May be nil.
 @param defaultValue the value to return by default if the action is not handled.
 @return a boolean value which depends on actionIdentifier.
 */
- (BOOL)cell:(id<MXKCellRendering>)cell shouldDoAction:(NSString*)actionIdentifier userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue;

@end

