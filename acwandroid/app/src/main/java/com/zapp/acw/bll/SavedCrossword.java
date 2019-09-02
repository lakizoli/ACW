package com.zapp.acw.bll;

import java.util.HashSet;
import java.util.Set;

public final class SavedCrossword {
	public String path;
	public String packageName;
	public String name;

	public int width = 0;
	public int height = 0;
	public HashSet<String> words = new HashSet<> ();

	private static native void deleteUsedWordsFromDB (String packagePath, Set<String> words);

	public void eraseFromDisk () {
		//Delete used words from db
		if (words != null && words.size () > 0) {
			String packagePath = path.substring (0, path.lastIndexOf ('/'));
			deleteUsedWordsFromDB (packagePath, words);
		}

//		//Delete filled values
//		NSURL *filledValuesPath = [self filledValuesPath];
//		err = nil;
//		if ([man removeItemAtURL:filledValuesPath error:&err] != YES) {
//			NSLog (@"Cannot delete crossword's filled values at path: %@, error: %@", filledValuesPath, err);
//		}
//
//		//Delete crossword
//		err = nil;
//		if ([man removeItemAtURL:_path error:&err] != YES) {
//			NSLog (@"Cannot delete crossword at path: %@, error: %@", _path, err);
//		}
	}

//	-(void) loadDB;
//	-(void) unloadDB;
//
//	-(void) saveFilledValues:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues;
//	-(void) loadFilledValuesInto:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues;
//
//	-(NSArray<Statistics*>*) loadStatistics;
//	-(void) mergeStatistics:(uint32_t) failCount hintCount:(uint32_t)hintCount fillRatio:(double)fillRatio isFilled:(BOOL)isFilled fillDuration:(NSTimeInterval)fillDuration;
//	-(void) resetStatistics;
//
//	-(uint32_t) getCellTypeInRow:(uint32_t)row col:(uint32_t)col;
//	-(BOOL) isStartCell:(uint32_t)row col:(uint32_t)col;
//	-(NSString*) getCellsQuestion:(uint32_t)row col:(uint32_t)col questionIndex:(uint32_t)questionIndex;
//	-(NSString*) getCellsValue:(uint32_t)row col:(uint32_t)col;
//	-(uint32_t) getCellsSeparators:(uint32_t)row col:(uint32_t)col;
//
//	-(NSSet<NSString*>*) getUsedKeys;
}
