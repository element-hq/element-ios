/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewController.h"

@class MXKCountryPickerViewController;

/**
 `MXKCountryPickerViewController` delegate.
 */
@protocol MXKCountryPickerViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a country.
 
 @param countryPickerViewController the `MXKCountryPickerViewController` instance.
 @param isoCountryCode the ISO 3166-1 country code representation.
 */
- (void)countryPickerViewController:(MXKCountryPickerViewController*)countryPickerViewController didSelectCountry:(NSString*)isoCountryCode;

@end

/**
 'MXKCountryPickerViewController' instance displays the list of supported countries. 
 */
@interface MXKCountryPickerViewController : MXKTableViewController <UISearchResultsUpdating>

/**
The searchController used to manage search.
*/
@property (nonatomic, strong) UISearchController *searchController;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKCountryPickerViewControllerDelegate> delegate;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKCountryPickerViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `countryPickerViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKCountryPickerViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKCountryPickerViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)countryPickerViewController;

/**
 Show/Hide the international dialing code for each country (NO by default).
 */
@property (nonatomic) BOOL showCountryCallingCode;

@end

