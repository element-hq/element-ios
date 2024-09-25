/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 'TableViewCellWithPhoneNumberTextField' inherits 'MXKTableViewCellWithLabelAndTextField' class.
 It may be used to fill a phone number.
 */
@interface TableViewCellWithPhoneNumberTextField : MXKTableViewCellWithLabelAndTextField
{
}

@property (strong, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (strong, nonatomic) IBOutlet UILabel *isoCountryCodeLabel;

/**
 The current selected country code
 */
@property (nonatomic) NSString *isoCountryCode;

@end
