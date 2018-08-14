//
//  PackageManager.mm
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "PackageManager.h"
#include "adb.hpp"

@implementation PackageManager

-(id)init {
	self = [super init];
	if (self) {
		//...
	}
	return self;
}

+(PackageManager*) sharedInstance {
	static PackageManager *instance = nil;
	if (instance == nil) {
		instance = [[PackageManager alloc] init];
	}
	return instance;
}

#pragma mark - Collecting packages

- (BOOL) ensureDirExists:(NSURL*)dir {
	NSFileManager *fileManager = [NSFileManager defaultManager];

	BOOL isDir = NO;
	BOOL exists = [fileManager fileExistsAtPath:[dir path] isDirectory:&isDir] == YES;
	
	BOOL createDir = NO;
	if (!exists) { //We have nothing at destination, so let's create a dir...
		createDir = YES;
	} else if (!isDir) { //We have some file at place, so we have to delete it before creating the dir...
		NSError *err = nil;
		if ([fileManager removeItemAtPath:[dir path] error:&err] != YES) {
			NSLog (@"Cannot remove file at path: %@, err: %@", [dir path], err);
			return NO;
		}
		createDir = YES;
	}
	
	if (createDir) {
		NSError *err = nil;
		if ([fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err] != YES) {
			NSLog (@"Cannot create database at url: %@, err: %@", dir, err);
			return NO;
		}
	}
	
	return YES;
}

- (NSURL*) documentPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL*) databasePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *docDir = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *dbDir = [docDir URLByAppendingPathComponent:@"packages" isDirectory:YES];
	
	if (![self ensureDirExists:dbDir]) {
		return nil;
	}
	
	return dbDir;
}

-(void) movePackagesFromDocToDB:(NSURL*)docDir dbDir:(NSURL*)dbDir {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
		NSDirectoryEnumerationSkipsPackageDescendants |
		NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:docDir
												  includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLNameKey]
																	 options:options
																errorHandler:nil];
	for (NSURL *fileURL in enumerator) {
		NSNumber *isFile = nil;
		if ([fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil] == YES && [isFile boolValue]) {
			NSString *name = nil;
			if ([fileURL getResourceValue:&name forKey:NSURLNameKey error:nil] == YES) {
				NSString *ext = [name pathExtension];
				if ([ext caseInsensitiveCompare:@"apkg"] == NSOrderedSame) {
					NSString *fileName = [[name lastPathComponent] stringByDeletingPathExtension];
					NSURL *packageDir = [dbDir URLByAppendingPathComponent:fileName isDirectory:YES];
					if ([self ensureDirExists:packageDir]) {
						NSURL *fileDestURL = [packageDir URLByAppendingPathComponent:@"package.apkg" isDirectory:NO];
						
						NSError *err = nil;
						BOOL resMove = [fileManager moveItemAtURL:fileURL toURL:fileDestURL error:&err];
						if (!resMove) {
							NSLog (@"Cannot move package to db at: %@", fileURL);
						}
					}
				}
			}
		}
	}
}

-(std::vector<std::shared_ptr<BasicInfo>>) readBasicPackageInfos:(NSURL*)dbDir {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
		NSDirectoryEnumerationSkipsPackageDescendants |
		NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:dbDir
												  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
																	 options:options
																errorHandler:nil];
	
	std::vector<std::shared_ptr<BasicInfo>> result;
	for (NSURL *dirURL in enumerator) {
		NSNumber *isDir = nil;
		if ([dirURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil] == YES && [isDir boolValue]) {
			std::shared_ptr<BasicInfo> basicInfo = BasicInfo::Create ([[dirURL path] UTF8String]);
			if (basicInfo) {
				result.push_back (basicInfo);
			}
		}
	}
	
	return result;
}

-(NSArray<Package*>*) collectPackages {
	NSURL *docDir = [self documentPath];
	NSURL *dbDir = [self databasePath];
	
	//Move packages from document dir to database
	[self movePackagesFromDocToDB:docDir dbDir:dbDir];
	
	//Prepare packages in database
	std::vector<std::shared_ptr<BasicInfo>> basicInfos = [self readBasicPackageInfos:dbDir];
	
	//Extract package's level1 informations
	NSMutableArray<Package*> *result = [NSMutableArray<Package*> new];
	for (std::shared_ptr<BasicInfo> db : basicInfos) {
		Package *pack = [[Package alloc] init];
		[pack setPath:[NSURL fileURLWithPath:[NSString stringWithUTF8String:db->GetPath ().c_str ()]]];
		[pack setName:[NSString stringWithUTF8String:db->GetPackageName ().c_str ()]];

		for (auto& it : db->GetDecks ()) {
			Deck *deck = [[Deck alloc] init];
			
			[deck setPackage:pack];
			[deck setDeckID:it.first];
			[deck setName:[NSString stringWithUTF8String:it.second->name.c_str ()]];
			
			[[pack decks] addObject:deck];
		}
		
		[result addObject:pack];
	}
	
	return result;
}

#pragma mark - Collecting saved crosswords of package

//...

#pragma mark - Collecting generation info

-(GeneratorInfo*)collectGeneratorInfo:(NSArray<Deck*>*)decks {
	if ([decks count] < 1) {
		return nil;
	}
	
	//Collect most decks with same modelID (all of them have to be the same, but not guaranteed!)
	__block NSURL *packagePath;
	__block std::vector<std::shared_ptr<CardList>> cardListsOfDecks;
	__block std::map<uint64_t, std::set<uint64_t>> deckIndicesByModelID;
	[decks enumerateObjectsUsingBlock:^(Deck * _Nonnull deck, NSUInteger idx, BOOL * _Nonnull stop) {
		if (packagePath == nil) {
			packagePath = [[deck package] path];
		}
		
		std::shared_ptr<CardList> cardList = CardList::Create ([[[[deck package] path] path] UTF8String], [deck deckID]);
		cardListsOfDecks.push_back (cardList);
		if (cardList) {
			const std::map<uint64_t, std::shared_ptr<CardList::Card>>& cards = cardList->GetCards ();
			if (cards.size () > 0) {
				uint64_t modelID = cards.begin ()->second->modelID;
				auto it = deckIndicesByModelID.find (modelID);
				if (it == deckIndicesByModelID.end ()) {
					deckIndicesByModelID.emplace (modelID, std::set<uint64_t> { (uint64_t) idx });
				} else {
					it->second.insert ((uint64_t) idx);
				}
			}
		}
	}];
	
	if (deckIndicesByModelID.size () <= 0 || cardListsOfDecks.size () != [decks count]) {
		return nil;
	}
	
	BOOL foundOneModelID = NO;
	uint64_t maxCount = 0;
	uint64_t choosenModelID = 0;
	for (auto it : deckIndicesByModelID) {
		if (it.second.size () > maxCount) {
			choosenModelID = it.first;
			maxCount = it.second.size ();
			foundOneModelID = YES;
		}
	}
	
	if (!foundOneModelID) {
		return nil;
	}

	//Collect generator info
	GeneratorInfo *info = [[GeneratorInfo alloc] init];
	
	auto itDeckIndices = deckIndicesByModelID.find (choosenModelID);
	if (itDeckIndices == deckIndicesByModelID.end ()) {
		return nil;
	}
	
	BOOL isFirstDeck = YES;
	for (uint64_t deckIdx : itDeckIndices->second) {
		std::shared_ptr<CardList> cardList = cardListsOfDecks[deckIdx];
		if (cardList == nullptr) {
			continue;
		}
		
		[[info decks] addObject:[decks objectAtIndex:deckIdx]];
		
		if (isFirstDeck) { //Collect fields from first deck only
			isFirstDeck = NO;
			
			for (auto it : cardList->GetFields ()) {
				Field *field = [[Field alloc] init];
				
				[field setName:[NSString stringWithUTF8String:it.second->name.c_str ()]];
				[field setIdx:it.second->idx];
				
				[[info fields] addObject:field];
			}
		}
		
		for (auto it : cardList->GetCards ()) {
			Card *card = [[Card alloc] init];
			
			[card setCardID:it.second->cardID];
			[card setNoteID:it.second->noteID];
			[card setModelID:it.second->modelID];
			
			for (const std::string& fieldValue : it.second->fields) {
				[[card fieldValues] addObject:[NSString stringWithUTF8String:fieldValue.c_str ()]];
			}
			
			[card setSolutionFieldValue:[NSString stringWithUTF8String:it.second->solutionField.c_str ()]];
			
			[[info cards] addObject:card];
		}

	}
	
	return info;
}

#pragma mark - Generate crossword based on info

-(void) generateWithInfo:(GeneratorInfo*)info {
	if (info == nil) {
		return;
	}
	
	if ([[info decks] count] < 1) {
		return;
	}
	
	NSString *packagePath = [[[[[info decks] objectAtIndex:0] package] path] path];
	
	__block std::set<uint64_t> deckIDs;
	[[info decks] enumerateObjectsUsingBlock:^(Deck * _Nonnull deck, NSUInteger idx, BOOL * _Nonnull stop) {
		deckIDs.insert ([deck deckID]);
	}];
	
	__block std::vector<std::string> questionFieldValues;
	__block std::vector<std::string> solutionFieldValues;
	[[info cards] enumerateObjectsUsingBlock:^(Card * _Nonnull card, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *val = [[card fieldValues] objectAtIndex:[info questionFieldIndex]];
		questionFieldValues.push_back ([val UTF8String]);
		
		val = [[card fieldValues] objectAtIndex:[info solutionFieldIndex]];
		solutionFieldValues.push_back ([val UTF8String]);
	}];
	
	//TODO: generate from field values directly...
	
	if (questionFieldValues.size() > 0) {
	}
	
//	std::shared_ptr<DeckSet> deckSet = DeckSet::Create ([packagePath UTF8String],
//														deckIDs,
//														std::set<uint64_t> {},
//														[info questionFieldIndex],
//														[info solutionFieldIndex]);
//
//	if (deckSet == nullptr) {
//		return;
//	}
}

@end
