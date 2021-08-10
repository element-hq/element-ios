//
//  SCSegmentControlFlowLayout.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/24.
//

#import "SCSegmentControlFlowLayout.h"

@interface SCSegmentControlFlowLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutAttributes;

@end

@implementation SCSegmentControlFlowLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    if (!CGRectEqualToRect(CGRectZero, self.collectionView.frame)) {
        [self.layoutAttributes removeAllObjects];

        NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];

        UICollectionViewLayoutAttributes *previousAttributes = nil;
        for (NSInteger index = 0; index < itemsCount; index++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            
            UICollectionViewLayoutAttributes *originAttribute = [self layoutAttributesForItemAtIndexPath:indexPath];
            CGRect attributeFrame = CGRectMake(index ? CGRectGetMaxX(previousAttributes.frame) + self.itemSpacing : 0, 0, originAttribute.frame.size.width, self.collectionView.frame.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom);

            UICollectionViewLayoutAttributes *attribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attribute.frame = attributeFrame;
            [self.layoutAttributes addObject:attribute];
            previousAttributes = attribute;
        }
    }
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return self.layoutAttributes;
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(CGRectGetMaxX(self.layoutAttributes.lastObject.frame), self.layoutAttributes.lastObject.frame.size.height);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

#pragma mark - Lazy Load

- (NSMutableArray<UICollectionViewLayoutAttributes *> *)layoutAttributes {
    if (!_layoutAttributes) {
        _layoutAttributes = [NSMutableArray array];
    }
    return _layoutAttributes;
}

@end
