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

-(CGFloat)gridOffsetX {
	return _gridOffsetX;
}

-(CGFloat)gridOffsetY {
	return _gridOffsetY;
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
	CGFloat collectionViewWidth = (self.collectionView.bounds.size.width - (contentInset.left + contentInset.right)) * _scaleFactor;
	CGFloat collectionViewHeight = (self.collectionView.bounds.size.height - (contentInset.top + contentInset.bottom)) * _scaleFactor;
	
	CGFloat cellSumWidth = _columnCount * _cellWidth * _scaleFactor;
	_gridOffsetX = 0;
	if (collectionViewWidth > cellSumWidth) {
		_gridOffsetX = (collectionViewWidth - cellSumWidth) / 2.0;
	}
	
	CGFloat cellSumHeight = _rowCount * _cellHeight * _scaleFactor;
	_gridOffsetY = 0;
	if (collectionViewHeight > cellSumHeight) {
		_gridOffsetY = (collectionViewHeight - (cellSumHeight + _navigationBarHeight + _statusBarHeight)) / 2.0;
	}
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	return YES;
}

- (CGSize) collectionViewContentSize {
	return CGSizeMake (_gridOffsetX + _columnCount * _cellWidth * _scaleFactor, _gridOffsetY + _rowCount * _cellHeight * _scaleFactor);
}

- (NSArray<UICollectionViewLayoutAttributes *> *) layoutAttributesForElementsInRect:(CGRect)rect {
	@autoreleasepool {
		NSMutableArray<UICollectionViewLayoutAttributes*> *visibleLayoutAttributes = [NSMutableArray<UICollectionViewLayoutAttributes*> new];
		
		NSInteger left = rect.origin.x;
		NSInteger right = left + rect.size.width;
		NSInteger top = rect.origin.y;
		NSInteger bottom = top + rect.size.height;
		
		NSInteger startRowInclusive = top / (NSInteger) (_cellHeight * _scaleFactor);
		NSInteger endRowInclusive = bottom / (NSInteger) (_cellHeight * _scaleFactor);
		if (bottom % (NSInteger) (_cellHeight * _scaleFactor) > 0) {
			++endRowInclusive;
		}

		NSInteger startColInclusive = left / (NSInteger) (_cellWidth * _scaleFactor);
		NSInteger endColInclusive = right / (NSInteger) (_cellWidth * _scaleFactor);
		if (right % (NSInteger) (_cellWidth * _scaleFactor) > 0) {
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
				[attr setFrame:CGRectMake (_gridOffsetX + col * _cellWidth * _scaleFactor,
										   _gridOffsetY + row * _cellHeight * _scaleFactor,
										   _cellWidth * _scaleFactor,
										   _cellHeight * _scaleFactor)];
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
		[attr setFrame:CGRectMake (_gridOffsetX + col * _cellWidth * _scaleFactor,
								   _gridOffsetY + row * _cellHeight * _scaleFactor,
								   _cellWidth * _scaleFactor,
								   _cellHeight * _scaleFactor)];
		return attr;
	}
}

@end
