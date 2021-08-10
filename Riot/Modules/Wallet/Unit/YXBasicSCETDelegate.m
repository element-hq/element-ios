//
//  YXBasicSCETDelegate.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXBasicSCETDelegate.h"

@implementation YXBasicSCETDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.BlockTableViewDidSelectRowAtIndexPath) {
        self.BlockTableViewDidSelectRowAtIndexPath(tableView, indexPath);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (self.BlockTableViewheightForHeaderInSection) {
       return self.BlockTableViewheightForHeaderInSection(tableView, section);
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (self.BlockTableViewviewForHeaderInSection) {
        return self.BlockTableViewviewForHeaderInSection(tableView,section);
    }
    return nil;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.BlockscrollViewDidScroll) {
        self.BlockscrollViewDidScroll(scrollView);
    }
}
@end
