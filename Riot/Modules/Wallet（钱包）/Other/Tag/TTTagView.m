//
//  TTTagView.m
//  QQtagView
//
//  Created by 王家强 on 2020/6/19.
//  Copyright © 2020 ZhangQun. All rights reserved.
//

#import "TTTagView.h"

@implementation TTTagItem

- (void)setModel:(id)model
{
    _model = model;
    if ([model isKindOfClass:[NSString class]]) {
        [self setTitle:model forState:UIControlStateNormal];
    }
    if ([model isKindOfClass:[NSDictionary class]]) {
        NSString *title = [model objectForKey:@"name"];
        [self setTitle:title forState:UIControlStateNormal];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        [self setBackgroundColor:self.selectedBackgroundColor];
        [self.layer setBorderColor:self.selectedBorderColor.CGColor];
    } else {
        [self setBackgroundColor:self.normalBackgroundColor];
        [self.layer setBorderColor:self.normalBorderColor.CGColor];
    }
}


- (void)setNormalBackgroundColor:(UIColor *)normalBackgroundColor
{
    _normalBackgroundColor = normalBackgroundColor;
    [self setBackgroundColor:_normalBackgroundColor];
}

- (void)setNormalBorderColor:(UIColor *)normalBorderColor
{
    _normalBorderColor = normalBorderColor;
    [self.layer setBorderColor:self.normalBorderColor.CGColor];
}

@end

#pragma mark ++++++++++++++++++ TagView ++++++++++++++++++
@interface TTTagView ()<UIScrollViewDelegate>


@property(nonatomic,assign) CGSize contentSize;

// tag数组
@property(nonatomic,strong) NSMutableArray <UIButton *> *selectBtns;

@property(nonatomic,strong) UIScrollView *scrollView;

@property(nonatomic,strong) UIPageControl *pageControl;

@end


@implementation TTTagView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tagTextColor = [UIColor colorWithRed:41/255.0 green:51/255.0 blue:64/255.0 alpha:1.0];
        _tagSelectedTextColor = [UIColor colorWithRed:41/255.0 green:51/255.0 blue:64/255.0 alpha:1.0];
        _tagBorderColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:244/255.0 alpha:1.0];
        _tagSelectedBorderColor = [UIColor colorWithRed:3/255.0 green:155/255.0 blue:229/255.0 alpha:1.0];
        _tagBackgroundColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:244/255.0 alpha:1.0];
        _tagSelectedBackgroundColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:244/255.0 alpha:1.0];
        
        _pageIndicatorTintColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:244/255.0 alpha:1.0];
        _currentPageIndicatorTintColor = [UIColor colorWithRed:3/255.0 green:155/255.0 blue:229/255.0 alpha:1.0];
        
        _tagFont = [UIFont systemFontOfSize:12];
        _tagSelectedFont = [UIFont systemFontOfSize:12];
        
        _lineSpacing = 10;
        _itemSpacing = 6;
        
        _allowsSelection = YES;
        _allowsMultipleSelection = NO;
        _pageControlEnabled = YES;
        
        _numberOfLines = 0;
        _selectBtns = [NSMutableArray array];
        
        [self addSubview:self.scrollView];
//        [self addSubview:self.pageControl];
    }
    return self;
}

- (void)setTagsArray:(NSArray *)tagsArray
{
    _tagsArray = tagsArray;
    if (!tagsArray || !tagsArray.count) {
        [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    // 添加标签
    [self.selectBtns removeAllObjects];
    for (int i = 0; i < tagsArray.count; i++) {
        [self addTagWithModel:tagsArray[i]];
    }
   
}


/// 添加Tag
/// @param model tag数据
- (void)addTagWithModel:(id)model {
    CGRect frame = CGRectZero;
    if(self.scrollView.subviews && self.scrollView.subviews.count > 0) {
        frame = [self.scrollView.subviews lastObject].frame;
    }
    
    TTTagItem *item = [[TTTagItem alloc]initWithFrame:CGRectMake(0, 0, 26, 26)];
    item.model = model;
    
    //默认文本样式
    NSMutableAttributedString* btnDefaultAttr = [[NSMutableAttributedString alloc]initWithString:item.titleLabel.text?:@""];
    [btnDefaultAttr addAttribute:NSFontAttributeName value:self.tagFont range:NSMakeRange(0, item.titleLabel.text.length)];
    [btnDefaultAttr addAttribute:NSForegroundColorAttributeName value:self.tagTextColor range:NSMakeRange(0, item.titleLabel.text.length)];
    [item setAttributedTitle:btnDefaultAttr forState:UIControlStateNormal];
    
    // 选中字体颜色
    NSMutableAttributedString* btnSelectedAttr = [[NSMutableAttributedString alloc]initWithString:item.titleLabel.text?:@""];
    [btnSelectedAttr addAttribute:NSForegroundColorAttributeName value:self.tagSelectedTextColor range:NSMakeRange(0, item.titleLabel.text.length)];
    // 选中文字大小
    [btnSelectedAttr addAttribute:NSFontAttributeName value:self.tagSelectedFont range:NSMakeRange(0, item.titleLabel.text.length)];
    [item setAttributedTitle:btnSelectedAttr forState:UIControlStateSelected];
    
    [item setNormalBackgroundColor:self.tagBackgroundColor];
    [item setSelectedBackgroundColor:self.tagSelectedBackgroundColor];
    
    // 圆角
    item.layer.cornerRadius = (self.cornerRadius != 0)?self.cornerRadius:26 / 2.f;
    item.layer.masksToBounds = YES;
    // 边框颜色
    item.layer.borderWidth = 1;
    item.normalBorderColor = self.tagBorderColor;
    item.selectedBorderColor = self.tagSelectedBorderColor;
    
    [item addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
    
    // 获取frame
    item.contentEdgeInsets = UIEdgeInsetsMake(2, 9, 2, 9);
    [item sizeToFit];
    item.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    item.frame = CGRectMake(frame.origin.x, frame.origin.y, item.frame.size.width, item.frame.size.height);
    item.userInteractionEnabled = self.allowsSelection;
    
    [self.scrollView addSubview:item];
    
    // 选中控制
    if (self.selected) {
        item.selected = YES;
        [self.selectBtns addObject:item];
        self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
    }
}

- (void)addTag:(id)model
{
    [self addTagWithModel:model];
    if (![self.tagsArray containsObject:model]) {
        _tagsArray = [self.tagsArray arrayByAddingObject:model];
    }
    [self updateTagViewLayout];
}

- (void)removeTag:(id)model
{
    if (!self.scrollView.subviews.count) { return; }
    for (TTTagItem *item in self.scrollView.subviews) {
        if ([item.model isKindOfClass:[NSString class]] && [item.model isEqualToString:model]) {
            [self.selectBtns removeObject:item];
            self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
            _tagsArray = [self.scrollView.subviews valueForKeyPath:@"model"];
            [item removeFromSuperview];
            break;
        }
        if ([item.model isKindOfClass:[NSDictionary class]] && [item.model isEqualToDictionary:model]) {
            [self.selectBtns removeObject:item];
            self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
            _tagsArray = [self.scrollView.subviews valueForKeyPath:@"model"];
            [item removeFromSuperview];
            break;
        }
    }
    [self updateTagViewLayout];
}

#pragma mark - 事件响应
- (void)selectItem:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    //点击事件回调
    if (self.selectItemBlock) {
        self.selectItemBlock(sender);
    }
    
    //单选在这处理
    if (!self.allowsMultipleSelection) {
        if (sender.selected) {
            for (UIButton *btn in self.selectBtns) {
                btn.selected=NO;
            }
            [self.selectBtns removeAllObjects];
            [self.selectBtns addObject:sender];
            self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
        }else{
            [self.selectBtns removeAllObjects];
            self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
        }
        [self checkButtonState];
        return;
    }
    //多选处理
    if (sender.selected) {
        [self.selectBtns addObject:sender];
        self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
    } else {
        [self.selectBtns removeObject:sender];
        self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
    }
    // 检测按钮状态，最少选中一个
    [self checkButtonState];
}

// 检测按钮状态，最少选中一个
- (void)checkButtonState {
    int selectCount = 0;
    UIButton* selectedBtn = nil;
    for(int i=0;i < self.scrollView.subviews.count; i++){
        UIButton* btn = self.scrollView.subviews[i];
        if(btn.selected){
            selectCount++;
            selectedBtn = btn;
        }
    }
    if ((selectCount == 1) && self.allowsSelection) {
        // 只有一个就把这一个给禁用手势
        selectedBtn.userInteractionEnabled = YES;
    }else{
        // 解除禁用手势
        for(int i=0;i < self.scrollView.subviews.count; i++){
            UIButton* btn = self.scrollView.subviews[i];
            if(!btn.userInteractionEnabled && self.allowsSelection){
                btn.userInteractionEnabled = YES;
            }
        }
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = self.scrollView.contentOffset;
    CGFloat w = self.scrollView.frame.size.width;
    
    int index = (offset.x + w/2)/w;;
    self.pageControl.currentPage = index;
    
}

#pragma mark - layout subviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateTagViewLayout];
}

- (CGSize)intrinsicContentSize
{
    return self.contentSize;
}

- (void)updateTagViewLayout
{
    [UIView beginAnimations:nil context:nil];
    NSArray *items = self.scrollView.subviews;
    if (items.count == 0) {
        // 没有设置内容，内容大小为零
        _contentSize = CGSizeZero;
        return;
    }
    // 按钮高度
    CGFloat itemH = 26;
    CGFloat itemX = self.itemSpacing;
    CGFloat itemY = self.lineSpacing;
    
    CGFloat marginX = self.itemSpacing;
    CGFloat marginY = self.lineSpacing;
    
    CGRect frame = CGRectZero;
    NSInteger numberOfRows = 1;
    NSInteger page = 0;
    
    for(TTTagItem *item in items){
        // 默认选中状态
        if (self.defaultSelectTags.count && [self.defaultSelectTags containsObject:item.model]) {
            item.selected = YES;
            if (![self.selectBtns containsObject:item]) {
                [self.selectBtns addObject:item];
                self.selectTags = [self.selectBtns valueForKeyPath:@"model"];
            }
        }
        // 计算frame
        frame = item.frame;
        frame.origin.x = itemX;
        frame.origin.y = itemY;
        frame.size.width = frame.size.width;
        frame.size.height = itemH;
        
        // 换行判断
        CGFloat itemW = CGRectGetMaxX(frame) + marginX - page * self.frame.size.width;
        // 如果单行显示则不换行分页
        if (itemW - self.frame.size.width >= 2 && self.numberOfLines != 1) { // 允许有1-2的误差
            frame.origin.y = CGRectGetMaxY(frame) + marginY;
            frame.origin.x = marginX + page * self.frame.size.width;
            itemY = frame.origin.y;
            // 分页判断
            if (self.numberOfLines != 0 && self.numberOfLines == numberOfRows) {
                page += 1;
                numberOfRows = 0; // 重置
                frame.origin.x = page * self.frame.size.width + marginX;
                frame.origin.y = marginY;
                itemY = frame.origin.y;
                itemX = frame.origin.x;
            }
            numberOfRows++; // 标记行数
        }
        itemX = CGRectGetMaxX(frame) + marginX;
        item.frame = frame;
    }
    // 单行显示的不显示分页标识和分页显示
    if (self.numberOfLines == 1) {
        self.scrollView.pagingEnabled = NO;
        self.pageControlEnabled = NO;
    }
    
    CGSize newContentSize = CGSizeZero;
    if (self.numberOfLines != 0 && page > 0) {
        self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.numberOfLines * itemH + marginY * (self.numberOfLines + 1));
        if (self.pageControlEnabled) { //显示分页标识
            // 添加分页指示器
            self.pageControl.numberOfPages = page+1;
            self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.scrollView.frame), self.scrollView.frame.size.width, 20);
        }
        CGFloat pageControlH = self.pageControlEnabled?20:0;
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width*(page+1), self.scrollView.frame.size.height);
        newContentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(self.scrollView.frame)+pageControlH+marginY);
    } else {
        self.pageControl.frame = CGRectZero;
        self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, CGRectGetMaxY(frame)+marginY);
        // 单行显示的计算
        if (self.numberOfLines == 1) {
            self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX(frame) + marginY, self.scrollView.frame.size.height);
        } else {
            self.scrollView.contentSize = CGSizeMake(self.frame.size.width, self.scrollView.frame.size.height);
        }
        newContentSize = CGSizeMake(self.frame.size.width, CGRectGetMaxY(frame) + marginY);
    }
    if (!CGSizeEqualToSize(newContentSize, _contentSize)) {
        _contentSize = newContentSize;
        // 通知外部IntrinsicContentSize失效
        [self invalidateIntrinsicContentSize];
    }
    [UIView commitAnimations];
}

#pragma mark - lazy load
- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl
{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPage = 1;
        _pageControl.pageIndicatorTintColor = _pageIndicatorTintColor;
        _pageControl.currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
        // 通过图片自定义
//        [_pageControl setValue:_pageIndicatorImage forKeyPath:@"pageImage"];
//        [_pageControl setValue:_currentPageIndicatorImage forKeyPath:@"currentPageImage"];
    }
    return _pageControl;
}

#pragma mark - copy
- (id)copy
{
    return self;
}


@end
