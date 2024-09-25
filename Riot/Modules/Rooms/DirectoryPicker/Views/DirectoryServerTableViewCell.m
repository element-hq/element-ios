/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DirectoryServerTableViewCell.h"

#import "AvatarGenerator.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation DirectoryServerTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.descLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.defaultBackgroundColor = [UIColor clearColor];
}

- (void)render:(id<MXKDirectoryServerCellDataStoring>)cellData
{
    self.iconImageView.hidden = NO;

    if (cellData.icon)
    {
        self.iconImageView.image = cellData.icon;
    }
    else  if (cellData.thirdPartyProtocolInstance.icon)
    {
        // Presently the thirdPartyProtocolInstance.icon is not a Matrix Content URI (https://github.com/matrix-org/synapse/issues/4175).
        // Patch: We extract the expected URI from the URL
        NSString *iconURL = cellData.thirdPartyProtocolInstance.icon;
        NSString *mxMediaPrefix = [NSString stringWithFormat:@"/%@/download/", kMXContentPrefixPath];
        NSRange range = [iconURL rangeOfString:mxMediaPrefix];
        if (range.location != NSNotFound)
        {
            iconURL = [NSString stringWithFormat:@"%@%@", kMXContentUriScheme, [iconURL substringFromIndex:range.location + range.length]];
        }
        // Check also if we are using the authenticated endpoint
        else
        {
            mxMediaPrefix = [NSString stringWithFormat:@"/%@/download/", kMXAuthenticatedContentPrefixPath];
            range = [iconURL rangeOfString:mxMediaPrefix];
            if (range.location != NSNotFound)
            {
                iconURL = [NSString stringWithFormat:@"%@%@", kMXContentUriScheme, [iconURL substringFromIndex:range.location + range.length]];
            }
        }
        [self.iconImageView setImageURI:iconURL
                               withType:nil
                    andImageOrientation:UIImageOrientationUp
                           previewImage:[MXKTools paintImage:AssetImages.placeholder.image
                                                   withColor:ThemeService.shared.theme.tintColor]
                           mediaManager:cellData.mediaManager];
    }
    else
    {
        self.iconImageView.hidden = YES;
    }

    self.descLabel.text = cellData.desc;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
