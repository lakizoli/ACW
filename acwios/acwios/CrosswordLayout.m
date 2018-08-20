//
//  CrosswordLayout.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CrosswordLayout.h"

@implementation CrosswordLayout {
	NSMutableArray<UICollectionViewLayoutAttributes*> *_layoutAttrs;
}

- (void) prepareLayout {
	_layoutAttrs = [NSMutableArray<UICollectionViewLayoutAttributes*> new];
	
	for (NSInteger row = 0; row < _rowCount; ++row) {
		for (NSInteger col = 0; col < _columnCount; ++col) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:col inSection:row]; //row is the secion, and col is the row!
			UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
			[attr setFrame:CGRectMake (col * _cellWidth, row * _cellHeight, _cellWidth, _cellHeight)];
			[_layoutAttrs addObject:attr];
		}
	}
}

- (CGSize) collectionViewContentSize {
	return CGSizeMake (_columnCount * _cellWidth, _rowCount * _cellHeight);
}

- (NSArray<UICollectionViewLayoutAttributes *> *) layoutAttributesForElementsInRect:(CGRect)rect {
	__block NSMutableArray<UICollectionViewLayoutAttributes*> *visibleLayoutAttributes = [NSMutableArray<UICollectionViewLayoutAttributes*> new];
	
	[_layoutAttrs enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull attr, NSUInteger idx, BOOL * _Nonnull stop) {
		if (CGRectIntersectsRect ([attr frame], rect)) {
			[visibleLayoutAttributes addObject:attr];
		}
	}];

	return visibleLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger idx = indexPath.section * _columnCount + indexPath.row;
	return [_layoutAttrs objectAtIndex:idx];
}

@end
