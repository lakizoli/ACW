//
//  CrosswordLayout.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CrosswordLayout.h"

@implementation CrosswordLayout {
	CGFloat _gridOffsetX;
	CGFloat _gridOffsetY;
}

- (NSIndexPath*) getIndexPathForRow:(NSInteger)row col:(NSInteger)col {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:col inSection:row]; //row is the secion, and col is the row!
	return indexPath;
}

- (NSInteger) getRowFromIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section;
}

- (NSInteger) getColFromIndexPath:(NSIndexPath*)indexPath {
	return indexPath.row;
}

#pragma mark - Collection View Layout functions

- (void) prepareLayout {
	UIEdgeInsets contentInset = self.collectionView.contentInset;
	CGFloat collectionViewWidth = self.collectionView.bounds.size.width - (contentInset.left + contentInset.right);
	CGFloat collectionViewHeight = self.collectionView.bounds.size.height - (contentInset.top + contentInset.bottom);
	
	CGFloat cellSumWidth = _columnCount * _cellWidth;
	_gridOffsetX = 0;
	if (collectionViewWidth > cellSumWidth) {
		_gridOffsetX = (collectionViewWidth - cellSumWidth) / 2.0;
	}
	
	CGFloat cellSumHeight = _rowCount * _cellHeight;
	_gridOffsetY = 0;
	if (collectionViewHeight > cellSumHeight) {
		_gridOffsetY = (collectionViewHeight - (cellSumHeight + _navigationBarHeight + _statusBarHeight)) / 2.0;
	}
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	return YES;
}

- (CGSize) collectionViewContentSize {
	return CGSizeMake (_gridOffsetX + _columnCount * _cellWidth, _gridOffsetY + _rowCount * _cellHeight);
}

- (NSArray<UICollectionViewLayoutAttributes *> *) layoutAttributesForElementsInRect:(CGRect)rect {
	@autoreleasepool {
		NSMutableArray<UICollectionViewLayoutAttributes*> *visibleLayoutAttributes = [NSMutableArray<UICollectionViewLayoutAttributes*> new];
		
		NSInteger left = rect.origin.x;
		NSInteger right = left + rect.size.width;
		NSInteger top = rect.origin.y;
		NSInteger bottom = top + rect.size.height;
		
		NSInteger startRowInclusive = top / (NSInteger) _cellHeight;
		NSInteger endRowInclusive = bottom / (NSInteger) _cellHeight;
		if (bottom % _cellHeight > 0) {
			++endRowInclusive;
		}

		NSInteger startColInclusive = left / (NSInteger) _cellWidth;
		NSInteger endColInclusive = right / (NSInteger) _cellWidth;
		if (right % _cellWidth > 0) {
			++endColInclusive;
		}
		
		startRowInclusive = MAX (startRowInclusive, 0);
		endRowInclusive = MIN (endRowInclusive, _rowCount - 1);
		startColInclusive = MAX (startColInclusive, 0);
		endColInclusive = MIN (endColInclusive, _columnCount - 1);
		
		for (NSInteger row = startRowInclusive; row <= endRowInclusive; ++row) {
			for (NSInteger col = startColInclusive; col <= endColInclusive; ++col) {
				NSIndexPath *indexPath = [self getIndexPathForRow:row col:col];
				UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
				[attr setFrame:CGRectMake (_gridOffsetX + col * _cellWidth, _gridOffsetY + row * _cellHeight, _cellWidth, _cellHeight)];
				if (attr && CGRectIntersectsRect ([attr frame], rect)) {
					[visibleLayoutAttributes addObject:attr];
				}
			}
		}

		return visibleLayoutAttributes;
	}
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	@autoreleasepool {
		NSInteger row = [self getRowFromIndexPath:indexPath];
		NSInteger col = [self getColFromIndexPath:indexPath];
		UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
		[attr setFrame:CGRectMake (_gridOffsetX + col * _cellWidth, _gridOffsetY + row * _cellHeight, _cellWidth, _cellHeight)];
		return attr;
	}
}

@end
