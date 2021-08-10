//
//  YXBaseTableViewCell.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/22.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXBaseTableViewCell.h"

@implementation YXBaseTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}



@end
