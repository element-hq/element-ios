//
//  YXNodeDetailModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailModel.h"

@implementation YXNodeDetailModel

- (NSMutableArray <YXNodeDetailModel *>*)getCellArray:(YXNodeListdata *)model{
    NSMutableArray *array = [NSMutableArray array];
    

    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:([model.status isEqualToString:@"ENABLED"] || [model.status isEqualToString:@"PRE_ENABLED"]) ? @"正常运行" : @"节点掉线" title:@"节点状态" showLine:YES]];
    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:model.createTime title:@"激活时间" showLine:YES]];
    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:model.payee title:@"收益地址" showLine:YES]];
    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:model.genkey title:@"质押信息" showLine:YES]];
    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:model.ip title:@"节点IP" showLine:YES]];
    [array addObject:[self createModelWithCellName:@"YXNodeDetailTableViewCell" cellHeight:52 desc:model.lastSendTime title:@"节点到期时间" showLine:YES]];
    return array;
}

- (YXNodeDetailModel *)createModelWithCellName:(NSString *)cellName cellHeight:(CGFloat)cellheight desc:(NSString *)desc title:(NSString *)title  showLine:(BOOL)showLine{
    YXNodeDetailModel *model = [[YXNodeDetailModel alloc]init];
    model.cellName = cellName;
    model.desc = desc;
    model.title = title;
    model.cellHeight = cellheight + model.descHeight;
    model.showLine = showLine;
    return model;
}

-(CGFloat)descHeight{
    return [self calculateLabelHeightWith:self.desc andWidth:SCREEN_WIDTH - 62 andFont:12];
}


- (CGFloat)calculateLabelHeightWith:(NSString *)text andWidth:(CGFloat)width andFont:(CGFloat)font{
    UILabel *label = [[UILabel alloc]init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:font];
    label.text = text;
    CGFloat labelHeight = [label sizeThatFits:CGSizeMake(width, MAXFLOAT)].height;
    return labelHeight;
}

@end
