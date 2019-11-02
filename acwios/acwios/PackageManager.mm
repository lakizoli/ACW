//
//  PackageManager.mm
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "PackageManager.h"
#include "adb.hpp"
#include "cw.hpp"
#include <unzip.h>

#pragma mark - FirstContentXmlParserDelegate

@interface FirstContentXmlParserDelegate : NSObject<NSXMLParserDelegate>

@property (assign) BOOL firstElementEnded;
@property (strong) NSString *firstValue;

@end

@implementation FirstContentXmlParserDelegate

-(id)init {
	self = [super init];
	if (self) {
		_firstElementEnded = NO;
	}
	return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (!_firstElementEnded) {
		if (_firstValue == nil) {
			_firstValue = string;
		} else {
			_firstValue = [_firstValue stringByAppendingString:string];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	_firstElementEnded = YES;
}

@end

#pragma mark - PackageManager

@implementation PackageManager {
	NSURL *_overriddenDocURL;
	NSURL *_overriddenDatabaseURL;
}

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

-(void)setOverriddenDocumentPath:(NSURL*)url {
	_overriddenDocURL = url;
}

-(void)setOverriddenDatabasePath:(NSURL*)url {
	_overriddenDatabaseURL = url;
}

-(void)unzipDownloadedPackage:(NSURL*)downloadedPackagePath packageName:(NSString*)packageName {
	//Check destination (if already exists we have to delete it!)
	NSURL *packagesPath = [self databasePath];
	NSURL *destPath = [packagesPath URLByAppendingPathComponent:packageName];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	BOOL exists = [fileManager fileExistsAtPath:[destPath path] isDirectory:&isDir] == YES;
	if (exists) {
		if ([fileManager removeItemAtURL:destPath error:nil] != YES) {
			NSLog (@"Cannot unzip package, because its already exist, and cannot be removed!");
			return;
		}
	}
	
	//Create the new dir
	if (![self ensureDirExists:destPath]) {
		return;
	}
	
	//Unzip package's content
	unzFile pack = unzOpen ([[downloadedPackagePath path] UTF8String]);
	if (pack == nullptr) {
		NSLog (@"Cannot open package to unzip!");
		return;
	}
	
	BOOL first = YES;
	while (true) {
		//Locate the next file
		int32_t nextFileRes = first ? unzGoToFirstFile (pack) : unzGoToNextFile (pack);
		if (nextFileRes != UNZ_OK && nextFileRes != UNZ_END_OF_LIST_OF_FILE) {
			NSLog (@"Cannot locate file in package to unzip!");
			return;
		}
		first = NO;
		
		//Read file info
		unz_file_info fileInfo;
		char fileNameBuffer[512];
		if (unzGetCurrentFileInfo (pack, &fileInfo, fileNameBuffer, 512, nullptr, 0, nullptr, 0) != UNZ_OK) {
			NSLog (@"Cannot read file info in package to unzip!");
			return;
		}
		
		if (fileInfo.size_filename >= 512) {
			NSLog (@"Filename too long in package to unzip!");
			return;
		}
		
		std::string fileName (&fileNameBuffer[0], &fileNameBuffer[fileInfo.size_filename]);

		//Unpack file to the destination
		if (unzOpenCurrentFile (pack) != UNZ_OK) {
			NSLog (@"Cannot open file in package to unzip!");
			return;
		}
		
		NSURL *destFilePath = [destPath URLByAppendingPathComponent:[NSString stringWithUTF8String:fileName.c_str ()]];
		FILE *destFile = fopen ([[destFilePath path] UTF8String], "wb");
		if (destFile == nullptr) {
			NSLog (@"Cannot create file at destination!");
			return;
		}
		
		int32_t chunkLen = 1024*1024;
		std::vector<uint8_t> buffer (chunkLen);
		int32_t readLen = 0;
		while ((readLen = unzReadCurrentFile (pack, &buffer[0], chunkLen)) != 0) {
			if (fwrite (&buffer[0], 1, readLen, destFile) != readLen) {
				NSLog (@"Cannot write file at destination!");
				return;
			}
		}
		
		fclose (destFile);
		
		if (unzCloseCurrentFile (pack) != UNZ_OK) {
			NSLog (@"Cannot close file in package to unzip!");
			return;
		}

		//Check last file
		if (nextFileRes == UNZ_END_OF_LIST_OF_FILE) { //If we reached the last file in the last cycle, then break
			break;
		}
	}
	
	unzClose (pack);
}

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
	if (_overriddenDocURL) {
		return _overriddenDocURL;
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL*) databasePath {
	NSURL *dbDir = nil;
	if (_overriddenDatabaseURL) {
		dbDir = _overriddenDatabaseURL;
	} else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *docDir = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		dbDir = [docDir URLByAppendingPathComponent:@"packages" isDirectory:YES];
	}
	
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
						
						[fileManager removeItemAtURL:fileDestURL error:nil];
						
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

-(NSURL*)packageStateURL:(NSURL*)packURL {
	return [packURL URLByAppendingPathComponent:@"gamestate.json"];
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
			
			[deck setPackagePath:pack.path];
			[deck setDeckID:it.first];
			[deck setName:[NSString stringWithUTF8String:it.second->name.c_str ()]];
			
			[[pack decks] addObject:deck];
		}
		
		GameState *state = [[GameState alloc] init];
		[state loadFromURL:[self packageStateURL:[pack path]]];
		[pack setState:state];
		
		[result addObject:pack];
	}
	
	return result;
}

-(void)savePackageState:(Package*)pack {
	[[pack state] saveToURL:[self packageStateURL:[pack path]]];
}

#pragma mark - Collecting saved crosswords of package

-(NSArray<SavedCrossword*>*)collectSavedCrosswordsOfPackage:(NSString*)packageName packageDir:(NSURL*)packageDir {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
		NSDirectoryEnumerationSkipsPackageDescendants |
		NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:packageDir
												  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
																	 options:options
																errorHandler:nil];
	
	NSMutableArray<SavedCrossword*>* arr = [NSMutableArray<SavedCrossword*> new];
	for (NSURL *child in enumerator) {
		NSNumber *isDirectory = nil;
		NSString *fileName = nil;
		if ([child getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] == YES && [isDirectory boolValue] == NO &&
			[child getResourceValue:&fileName forKey:NSURLNameKey error:NULL] == YES && [fileName hasSuffix:@".cw"])
		{
//			NSLog (@"child: %@", child);
//			NSLog (@"file name: %@", fileName);
			
			std::shared_ptr<Crossword> loadedCW = Crossword::Load ([[child path] UTF8String]);
			if (loadedCW != nullptr) {
				SavedCrossword* cw = [[SavedCrossword alloc] init];
				[cw setPath:child];
				[cw setPackageName:packageName];
				[cw setName:[NSString stringWithUTF8String:loadedCW->GetName ().c_str ()]];
				
				std::shared_ptr<Grid> grid = loadedCW->GetGrid ();
				[cw setWidth:grid->GetWidth ()];
				[cw setHeight:grid->GetHeight ()];

				NSMutableSet<NSString*> *words = [NSMutableSet<NSString*> new];
				for (const std::wstring& word : loadedCW->GetWords ()) {
					NSUInteger len = word.length () * sizeof (wchar_t);
					NSString *nsWord = [[NSString alloc] initWithBytes:word.c_str () length:len encoding:NSUTF32LittleEndianStringEncoding];
					[words addObject:nsWord];
				}

				[cw setWords:words];
			
				[arr addObject:cw];
			}
		}
	}
	
	return arr;
}

-(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)collectSavedCrosswords {
	NSURL *dbDir = [self databasePath];
	
	//Enumerate packages in database and collect crosswords from it
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
		NSDirectoryEnumerationSkipsPackageDescendants |
		NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:dbDir
												  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
																	 options:options
																errorHandler:nil];
	
	NSMutableDictionary<NSString*, NSArray<SavedCrossword*>*> *res = [NSMutableDictionary<NSString*, NSArray<SavedCrossword*>*> new];
	for (NSURL *child in enumerator) {
		NSNumber *isDirectory = nil;
		if ([child getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] == YES && [isDirectory boolValue]) {
			NSString *packageName = nil;
			if ([child getResourceValue:&packageName forKey:NSURLNameKey error:NULL] == YES) {
				NSArray<SavedCrossword*> *packageCrosswords = [self collectSavedCrosswordsOfPackage:packageName packageDir:child];
				if ([packageCrosswords count] > 0) {
					NSArray<SavedCrossword*> *sortedCWs = [packageCrosswords sortedArrayUsingComparator:
						^NSComparisonResult(SavedCrossword*  _Nonnull cw1, SavedCrossword*  _Nonnull cw2) {
							return [[cw1 name] compare:[cw2 name]];
						}];
					[res setObject:sortedCWs forKey:packageName];
				}
			}
		}
	}
	
	return res;
}

#pragma mark - Calculating stat counts of a crossword

-(NSArray<NSNumber*>*)collectMinimalStatCountCWIndices:(NSString *)packageKey
									   savedCrosswords:(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)savedCrosswords
										 playedCWCount:(NSUInteger)playedCWCount
{
	NSArray<SavedCrossword*> *cws = [savedCrosswords objectForKey:packageKey];
	
	NSMutableDictionary<NSNumber*, NSMutableArray<NSNumber*>*> *indices = [NSMutableDictionary new];
	NSUInteger minCount = NSUIntegerMax;
	for (NSUInteger i = 0; i < playedCWCount; ++i) {
		SavedCrossword *cw = [cws objectAtIndex:i];
		NSArray<Statistics*> *stat = [cw loadStatistics];
		
		int32_t offset = [cw loadStatisticsOffset];
		if (offset < 0) {
			offset = 0;
		}
		
		if ([stat count] > 0 && [[stat lastObject] isFilled] == NO) {
			--offset;
		}
		
		int32_t count = (int32_t) stat.count + offset;
		NSNumber *cnt = [NSNumber numberWithUnsignedInteger: count];

		NSMutableArray<NSNumber*> *idcs = [indices objectForKey:cnt];
		if (idcs == nil) {
			idcs = [NSMutableArray<NSNumber*> new];
			[indices setObject:idcs forKey:cnt];
		}

		[idcs addObject:[NSNumber numberWithUnsignedInteger:i]];

		if (count < minCount) {
			minCount = count;
		}
	}
	
	if ([indices count] <= 0) {
		return nil;
	}
	
	return [indices objectForKey:[NSNumber numberWithUnsignedInteger:minCount]];
}

-(uint32_t)getMaxStatCountOfCWSet:(NSString*)packageKey {
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *savedCrosswords = [self collectSavedCrosswords];
	NSArray<SavedCrossword*>* cws = [savedCrosswords objectForKey:packageKey];
	
	NSUInteger maxCount = 0;
	for (NSUInteger i = 0, iEnd = [cws count]; i < iEnd; ++i) {
		SavedCrossword *cw = [cws objectAtIndex:i];
		
		int32_t offset = [cw loadStatisticsOffset];
		if (offset < 0) {
			offset = 0;
		}
		
		NSArray<Statistics*> *stat = [cw loadStatistics];
		
		int32_t count = (int32_t) stat.count + offset;
		if (count > maxCount) {
			maxCount = count;
		}
	}
	
	return (uint32_t) maxCount;
}

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
			packagePath = [deck packagePath];
		}
		
		std::shared_ptr<CardList> cardList = CardList::Create ([[[deck packagePath] path] UTF8String], [deck deckID]);
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

	//Read used words of package
	std::shared_ptr<UsedWords> usedWords = UsedWords::Create ([[packagePath path] UTF8String]);

	//Collect generator info
	GeneratorInfo *info = [[GeneratorInfo alloc] init];
	info.splitArray = @[@";", @"\uff1b", @"<br", @"/>", @"<div>", @"</div>",
						@"<span>", @"</span>", @"*", @"\r", @"\n", @",", @"\uff0c", @"(", @"\uff08", @")", @"\uff09",
						@"[", @"\uff3b", @"]", @"\uff3d", @"{", @"\uff5b", @"}", @"\uff5d"];
	info.solutionsFixes = [NSDictionary new];

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
	
	if (usedWords != nullptr) {
		for (const std::wstring& word : usedWords->GetWords ()) {
			NSUInteger len = word.length () * sizeof (wchar_t);
			NSString *nsWord = [[NSString alloc] initWithBytes:word.c_str () length:len encoding:NSUTF32LittleEndianStringEncoding];
			[info.usedWords addObject:nsWord];
		}
	}
	
	return info;
}

-(void) reloadUsedWords:(NSURL*)packagePath info:(GeneratorInfo*)info {
	[info.usedWords removeAllObjects];
	
	std::shared_ptr<UsedWords> usedWords = UsedWords::Create ([[packagePath path] UTF8String]);
	
	if (usedWords != nullptr) {
		for (const std::wstring& word : usedWords->GetWords ()) {
			NSUInteger len = word.length () * sizeof (wchar_t);
			NSString *nsWord = [[NSString alloc] initWithBytes:word.c_str () length:len encoding:NSUTF32LittleEndianStringEncoding];
			[info.usedWords addObject:nsWord];
		}
	}
}

#pragma mark - Generate crossword based on info

-(NSString*) trimQuestionField:(NSString*)questionField {
	__block NSString *field = [questionField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	//Try to detect HTML content
	if ([field hasPrefix:@"<"]) {
		FirstContentXmlParserDelegate *xmlDel = [[FirstContentXmlParserDelegate alloc] init];
		NSXMLParser *xml = [[NSXMLParser alloc] initWithData:[field dataUsingEncoding:NSUTF8StringEncoding]];
		[xml setDelegate:xmlDel];
		if ([xml parse]) {
			field = [xmlDel firstValue];
		} else {
			return nil;
		}
	}
	
	//Convert separators to usable format
	field = [field stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
	
	NSArray<NSString*> *separatorArr = @[@";", @"<br", @"/>", @"<div>", @"</div>", @"*", @"\r", @"\n"];
	[separatorArr enumerateObjectsUsingBlock:^(NSString * _Nonnull separatorStr, NSUInteger idx, BOOL * _Nonnull stop) {
		field = [field stringByReplacingOccurrencesOfString:separatorStr withString:@":"];
		field = [field stringByReplacingOccurrencesOfString:@"  " withString:@" "];
		field = [field stringByReplacingOccurrencesOfString:@": :" withString:@", "];
		field = [field stringByReplacingOccurrencesOfString:@"::" withString:@", "];
	}];

	field = [field stringByReplacingOccurrencesOfString:@":" withString:@", "];
	while ([field hasSuffix:@", "]) {
		field = [field substringToIndex:[field length] - 2];
	}

	//NSLog (@"%@ -> %@", questionField, field);
	return field;
}

-(NSString*) trimSolutionField:(NSString*)solutionField
					  splitArr:(NSArray<NSString*>*)splitArr
				 solutionFixes:(NSDictionary<NSString*, NSString*>*)solutionFixes
{
	NSString* fixedSolution = [solutionFixes objectForKey:solutionField];
	if (fixedSolution) {
		return fixedSolution;
	}
	
	__block NSString *field = [solutionField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	//Try to detect HTML content
	if ([field hasPrefix:@"<"]) {
		FirstContentXmlParserDelegate *xmlDel = [[FirstContentXmlParserDelegate alloc] init];
		NSXMLParser *xml = [[NSXMLParser alloc] initWithData:[field dataUsingEncoding:NSUTF8StringEncoding]];
		[xml setDelegate:xmlDel];
		if ([xml parse]) {
			field = [xmlDel firstValue];
		} else {
			return nil;
		}
	}
	
	//Replace chars in word
	NSDictionary<NSString*, NSString*> *replacePairs = @{ @"&nbsp;" : @" ",
														  @"  " : @" "
														  };
	[replacePairs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		field = [field stringByReplacingOccurrencesOfString:key withString:obj];
	}];
	
	//Pull word out from garbage
//	NSArray<NSString*> *splitArr = @[@";", @"<br", @"/>", @"<div>", @"</div>",
//									 @"<span>", @"</span>", @"*", @"\r", @"\n", @",", @"(", @")",
//									 @"[", @"]", @"{", @"}"];
	[splitArr enumerateObjectsUsingBlock:^(NSString*  _Nonnull splitStr, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *trimmed = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSArray<NSString*> *items = [trimmed componentsSeparatedByString:splitStr];
		if ([items count] > 0) {
			field = [items objectAtIndex:0];
		} else {
			field = trimmed;
		}
	}];
	
	//NSLog (@"%@ -> %@", solutionField, field);
	return field;
}

-(NSString*) generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback {
	if (info == nil) {
		return nil;
	}
	
	if ([[info decks] count] < 1) {
		return nil;
	}
	
	NSURL *packageUrl = [[[info decks] objectAtIndex:0] packagePath];
	NSString *packagePath = [packageUrl path];
	
	__block std::set<uint64_t> deckIDs;
	[[info decks] enumerateObjectsUsingBlock:^(Deck * _Nonnull deck, NSUInteger idx, BOOL * _Nonnull stop) {
		deckIDs.insert ([deck deckID]);
	}];
	
	__block std::vector<std::wstring> questionFieldValues;
	__block std::vector<std::wstring> solutionFieldValues;
	__block NSMutableSet<NSString*> *solutionFieldFilter = [NSMutableSet new];
	[[info cards] enumerateObjectsUsingBlock:^(Card * _Nonnull card, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([[card fieldValues] count] <= [info solutionFieldIndex] || [[card fieldValues] count] <= [info questionFieldIndex]) {
			return;
		}
		
		NSString *origSolutionVal = [[[card fieldValues] objectAtIndex:[info solutionFieldIndex]] lowercaseString];
		NSString *solutionVal = [self trimSolutionField:origSolutionVal splitArr:info.splitArray solutionFixes:info.solutionsFixes];
		if ([solutionVal length] <= 0) {
			return;
		}
		
		NSString *questionVal = [[card fieldValues] objectAtIndex:[info questionFieldIndex]];
		questionVal = [self trimQuestionField:questionVal];
		if ([questionVal length] <= 0) {
			return;
		}
		
		if ([solutionFieldFilter containsObject: solutionVal]) { //Filter duplicated solution values
			return;
		}
		[solutionFieldFilter addObject:solutionVal];
//		NSLog (@"%@ |||| %@", origSolutionVal, solutionVal);

		NSData *valData = [solutionVal dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
		solutionFieldValues.push_back (std::wstring ((const wchar_t*) [valData bytes], [valData length] / sizeof (wchar_t)));
		
		valData = [questionVal dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
		questionFieldValues.push_back (std::wstring ((const wchar_t*) [valData bytes], [valData length] / sizeof (wchar_t)));
	}];
	
	if (questionFieldValues.size () <= 0 || solutionFieldValues.size () <= 0 || questionFieldValues.size () != solutionFieldValues.size ()) {
		return nil;
	}
	
	__block std::vector<std::wstring> usedWordValues;
	[[info usedWords] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSData *valData = [obj dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
		usedWordValues.push_back (std::wstring ((const wchar_t*) [valData bytes], [valData length] / sizeof (wchar_t)));
	}];
	
	struct Query : public QueryWords {
		std::vector<std::wstring>& _words;
		std::function<void (const std::set<std::wstring>& values)> _updater;
		
		virtual uint32_t GetCount () const override final { return (uint32_t) _words.size (); }
		virtual const std::wstring& GetWord (uint32_t idx) const override final { return _words[idx]; }
		virtual void Clear () override final { _words.clear (); }
		virtual void UpdateWithSet (const std::set<std::wstring>& values) override {
			if (_updater) {
				_updater (values);
			}
		}
		Query (std::vector<std::wstring>& words, std::function<void (const std::set<std::wstring>&)> updater = nullptr) :
			_words (words), _updater (updater) {}
	};
	
	std::string packagePathForUsedWords = [packagePath UTF8String];
	auto updateUsedWords = [&packagePathForUsedWords] (const std::set<std::wstring>& usedWords) -> void {
		UsedWords::Update (packagePathForUsedWords, usedWords);
	};
	
	auto progressHandler = [progressCallback] (float progress) -> bool {
		BOOL stop = NO;
		progressCallback (progress, &stop);
		return stop != YES; //continue generation
	};
	
	std::shared_ptr<Generator> gen = Generator::Create ([packagePath UTF8String],
														[[info crosswordName] UTF8String],
														(uint32_t) [info width],
														(uint32_t) [info height],
														std::make_shared<Query> (questionFieldValues),
														std::make_shared<Query> (solutionFieldValues),
														std::make_shared<Query> (usedWordValues, updateUsedWords),
														progressHandler);
	if (gen == nullptr) {
		return nil;
	}
	
	std::shared_ptr<Crossword> cw = gen->Generate ();
	if (cw == nullptr) {
		return nil;
	}
	
	if (cw->GetWords().size () <= 0) { //We generated an empty crossword...
		return nil;
	}
	
	NSString *fileName = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".cw"];
	NSURL *fileUrl = [packageUrl URLByAppendingPathComponent:fileName];
	if (!cw->Save ([[fileUrl path] UTF8String])) {
		return nil;
	}

	return fileName;
}

@end
