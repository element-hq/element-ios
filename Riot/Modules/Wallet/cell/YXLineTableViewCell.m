//
//  YXLineTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXLineTableViewCell.h"

@implementation YXLineTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
}

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:UIColor.class]) {
        self.backgroundColor = (UIColor *)rowData;
    }
}

@end
