//
//  JsonImpl.mm
//  Common
//
//  Created by Laki, Zoltan on 2017. 09. 20..
//  Copyright © 2017. ZApp. All rights reserved.
//

#include "JsonImpl.hpp"
#import <Foundation/Foundation.h>

using namespace std;

////////////////////////////////////////////////////////////////////////////////////////////////////
// JSONBase
////////////////////////////////////////////////////////////////////////////////////////////////////
JsonBase::JsonBase (void* internalObject) {
	@autoreleasepool {
		bool succeeded = false;
		if (internalObject != nullptr) {
			NSObject* obj = (__bridge NSObject*)internalObject;
			if ([obj isKindOfClass:[NSMutableDictionary class]] || [obj isKindOfClass:[NSMutableArray class]]) {
				mData = (__bridge_retained void*)obj;
				succeeded = true;
			}
		}
		
		if (!succeeded) {
			mData = nullptr;
		}
	}
}

JsonBase::~JsonBase () {
	@autoreleasepool {
		if (mData != nullptr) {
			CFBridgingRelease (mData);
			mData = nullptr;
		}
	}
}

template<class ResultT, class ContainerT>
shared_ptr<ResultT> JsonBase::Parse (const ContainerT& jsonUTF8) {
	@autoreleasepool {
		if (jsonUTF8.size () <= 0) {
			return nullptr;
		}
		
		//Parse JSON
		NSError* error = nil;
		id jsonObj = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytesNoCopy:(void*)&jsonUTF8[0] length:jsonUTF8.size () freeWhenDone:NO]
													 options:NSJSONReadingMutableContainers
													   error:&error];
		if (error != nil) {
			return nullptr;
		}
		
		//Convert to C++
		shared_ptr<JsonBase> result;
		if ([jsonObj isKindOfClass:[NSMutableArray class]]) { //NSArray result
			result = shared_ptr<JsonArrayImpl> (new JsonArrayImpl ((__bridge void*)jsonObj));
		} else if ([jsonObj isKindOfClass:[NSMutableDictionary class]]) { //NSDictionary result
			result = shared_ptr<JsonObjectImpl> (new JsonObjectImpl ((__bridge void*)jsonObj));
		}
		
		return dynamic_pointer_cast<ResultT> (result);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JSONObject
////////////////////////////////////////////////////////////////////////////////////////////////////
shared_ptr<JsonObject> JsonObject::Create () {
	return shared_ptr<JsonObject> (new JsonObjectImpl ());
}

shared_ptr<JsonObject> JsonObject::Parse (const vector<uint8_t>& json) {
	return JsonBase::Parse<JsonObject, vector<uint8_t>> (json);
}

shared_ptr<JsonObject> JsonObject::Parse (const string& json) {
	return JsonBase::Parse<JsonObject, string> (json);
}

JsonObjectImpl::JsonObjectImpl () {
	@autoreleasepool {
		mData = (__bridge_retained void*)[[NSMutableDictionary alloc] init];
	}
}

bool JsonObjectImpl::HasNumber (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		return item != nil && [item isKindOfClass:[NSNumber class]];
	}
}

void JsonObjectImpl::Add (const string& key, const string& value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		
		NSString* str = [NSString stringWithUTF8String:value.c_str ()];
		if (str == nil) {
			str = @"";
		}
		
		[obj setObject:str
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, bool value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithBool:value ? YES : NO]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, int32_t value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithInt:value]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, int64_t value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithLongLong:value]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, uint32_t value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithUnsignedLong:value]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, uint64_t value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithUnsignedLongLong:value]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, double value) {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[NSNumber numberWithDouble:value]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, shared_ptr<JsonObject> value) {
	@autoreleasepool {
		shared_ptr<JsonObjectImpl> valueImpl = static_pointer_cast<JsonObjectImpl> (value);
		
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[((__bridge NSMutableDictionary*)valueImpl->mData) mutableCopy]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

void JsonObjectImpl::Add (const string& key, shared_ptr<JsonArray> value) {
	@autoreleasepool {
		shared_ptr<JsonArrayImpl> valueImpl = static_pointer_cast<JsonArrayImpl> (value);
		
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		[obj setObject:[((__bridge NSMutableArray*)valueImpl->mData) mutableCopy]
				forKey:[NSString stringWithUTF8String:key.c_str ()]];
	}
}

bool JsonObjectImpl::HasString (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		return item != nil && [item isKindOfClass:[NSString class]];
	}
}

bool JsonObjectImpl::HasObject (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		return item != nil && [item isKindOfClass:[NSMutableDictionary class]];
	}
}

bool JsonObjectImpl::HasArray (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		return item != nil && [item isKindOfClass:[NSMutableArray class]];
	}
}

string JsonObjectImpl::GetString (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return string ();
		}
		
		if (![item isKindOfClass:[NSString class]]) {
			return string ();
		}
		
		NSString* val = (NSString*)item;
		return [val UTF8String];
	}
}

bool JsonObjectImpl::GetBool (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val boolValue] != NO;
	}
}

int32_t JsonObjectImpl::GetInt32 (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val intValue];
	}
}

int64_t JsonObjectImpl::GetInt64 (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val longLongValue];
	}
}

uint32_t JsonObjectImpl::GetUInt32 (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return (uint32_t)[val unsignedLongValue];
	}
}

uint64_t JsonObjectImpl::GetUInt64 (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val unsignedLongLongValue];
	}
}

double JsonObjectImpl::GetDouble (const string& key) const {
	@autoreleasepool {
		NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return 0;
		}
		
		if (![item isKindOfClass:[NSNumber class]]) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val doubleValue];
	}
}

shared_ptr<JsonObject> JsonObjectImpl::GetObject (const string& key) const {
	@autoreleasepool {
		__weak NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		__weak id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return JsonObject::Create ();
		}
		
		if (![item isKindOfClass:[NSMutableDictionary class]]) {
			return JsonObject::Create ();
		}
	
		__weak NSMutableDictionary* val = (NSMutableDictionary*)item;
		return shared_ptr<JsonObject> (new JsonObjectImpl ((__bridge void*)val));
	}
}

shared_ptr<JsonArray> JsonObjectImpl::GetArray (const string& key) const {
	@autoreleasepool {
		__weak NSMutableDictionary* obj = (__bridge NSMutableDictionary*)mData;
		__weak id item = [obj objectForKey:[NSString stringWithUTF8String:key.c_str ()]];
		if (item == nil) {
			return JsonArray::Create ();
		}
		
		if (![item isKindOfClass:[NSMutableArray class]]) {
			return JsonArray::Create ();
		}
		
		__weak NSMutableArray* val = (NSMutableArray*)item;
		return shared_ptr<JsonArray> (new JsonArrayImpl ((__bridge void*)val));
	}
}

string JsonObjectImpl::ToString (bool prettyPrint) const {
	@autoreleasepool {
		NSError* err = nil;
		NSUInteger options = prettyPrint ? NSJSONWritingPrettyPrinted : 0;
		NSData* raw = [NSJSONSerialization dataWithJSONObject:(__bridge NSMutableDictionary*)mData options:options error:&err];
		if (raw == nil) { //Error
			return string ();
		}
		
		return [[[NSString alloc] initWithData:raw encoding:NSUTF8StringEncoding] UTF8String];
	}
}

vector<uint8_t> JsonObjectImpl::ToVector () const {
	@autoreleasepool {
		NSError* err = nil;
		NSData* raw = [NSJSONSerialization dataWithJSONObject:(__bridge NSMutableDictionary*)mData options:0 error:&err];
		if (raw == nil) { //Error
			return vector<uint8_t> ();
		}
		
		vector<uint8_t> buffer ([raw length]);
		[raw getBytes:&buffer[0] length:buffer.size()];
		return buffer;
	}
}

void JsonObjectImpl::IterateProperties (function<bool (const string& key, const string& value, JsonDataType type)> handleProperty) const {
	@autoreleasepool {
		NSMutableDictionary* jsonObj = (__bridge NSMutableDictionary*)mData;
		[jsonObj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			//Convert key
			if (![key isKindOfClass:[NSString class]]) { //Error
				return;
			}
			
			string jsonKey = [(NSString*)key UTF8String];
			
			//Convert value
			JsonDataType type = JsonDataType::Unknown;
			string jsonValue;
			if ([obj isKindOfClass:[NSString class]]) {
				type = JsonDataType::String;
				jsonValue = [(NSString*)obj UTF8String];
			} else if ([obj isKindOfClass:[NSNumber class]]) {
				const char* objCType = [obj objCType];
				if (strcmp (objCType, @encode (char)) == 0) {
					type = JsonDataType::Bool;
					jsonValue = [(NSNumber*)obj boolValue] ? "true" : "false";
				} else if (strcmp (objCType, @encode (int)) == 0) {
					type = JsonDataType::Int32;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (long long)) == 0) {
					type = JsonDataType::Int64;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (unsigned long)) == 0) {
					type = JsonDataType::UInt32;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (unsigned long long)) == 0) {
					type = JsonDataType::UInt64;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (double)) == 0) {
					type = JsonDataType::Double;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				}
			} else if ([obj isKindOfClass:[NSMutableArray class]]) {
				type = JsonDataType::Object;
				
				NSMutableDictionary* val = (NSMutableDictionary*)obj;
				jsonValue = JsonObjectImpl ((__bridge void*)val).ToString ();
			} else if ([obj isKindOfClass:[NSMutableDictionary class]]) {
				type = JsonDataType::Array;
				
				NSMutableArray* val = (NSMutableArray*)obj;
				jsonValue = JsonArrayImpl ((__bridge void*)val).ToString ();
			}
			
			if (type == JsonDataType::Unknown) { //Error
				return;
			}
			
			//Call the callback on each property
			if (!handleProperty (jsonKey, jsonValue, type)) {
				*stop = YES;
			}
		}];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JSONArray
////////////////////////////////////////////////////////////////////////////////////////////////////
shared_ptr<JsonArray> JsonArray::Create () {
	return shared_ptr<JsonArray> (new JsonArrayImpl ());
}

shared_ptr<JsonArray> JsonArray::Parse (const vector<uint8_t>& json) {
	return JsonBase::Parse<JsonArray, vector<uint8_t>> (json);
}

shared_ptr<JsonArray> JsonArray::Parse (const string& json) {
	return JsonBase::Parse<JsonArray, string> (json);
}

JsonArrayImpl::JsonArrayImpl () {
	@autoreleasepool {
		mData = (__bridge_retained void*)[[NSMutableArray alloc] init];
	}
}

bool JsonArrayImpl::HasNumberAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return false;
		}
		
		id item = [arr objectAtIndex:idx];
		return item != nil && [item isKindOfClass:[NSNumber class]];
	}
}

void JsonArrayImpl::Add (const string& value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSString stringWithUTF8String:value.c_str ()]];
	}
}

void JsonArrayImpl::Add (bool value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithBool:value ? YES : NO]];
	}
}

void JsonArrayImpl::Add (int32_t value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithInt:value]];
	}
}

void JsonArrayImpl::Add (int64_t value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithLongLong:value]];
	}
}

void JsonArrayImpl::Add (uint32_t value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithUnsignedLong:value]];
	}
}

void JsonArrayImpl::Add (uint64_t value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithUnsignedLongLong:value]];
	}
}

void JsonArrayImpl::Add (double value) {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[NSNumber numberWithDouble:value]];
	}
}

void JsonArrayImpl::Add (shared_ptr<JsonObject> value) {
	@autoreleasepool {
		shared_ptr<JsonObjectImpl> valueImpl = static_pointer_cast<JsonObjectImpl> (value);
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[((__bridge NSMutableDictionary*)valueImpl->mData) mutableCopy]];
	}
}

void JsonArrayImpl::Add (shared_ptr<JsonArray> value) {
	@autoreleasepool {
		shared_ptr<JsonArrayImpl> valueImpl = static_pointer_cast<JsonArrayImpl> (value);
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr addObject:[((__bridge NSMutableArray*)valueImpl->mData) mutableCopy]];
	}
}

int32_t JsonArrayImpl::GetCount () const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		return (int32_t)[arr count];
	}
}

bool JsonArrayImpl::HasStringAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return false;
		}
		
		id item = [arr objectAtIndex:idx];
		return item != nil && [item isKindOfClass:[NSString class]];
	}
}

bool JsonArrayImpl::HasObjectAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return false;
		}
		
		id item = [arr objectAtIndex:idx];
		return item != nil && [item isKindOfClass:[NSMutableDictionary class]];
	}
}

bool JsonArrayImpl::HasArrayAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return false;
		}
		
		id item = [arr objectAtIndex:idx];
		return item != nil && [item isKindOfClass:[NSMutableArray class]];
	}
}

string JsonArrayImpl::GetStringAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return string ();
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return string ();
		}
		
		NSString* val = (NSString*)item;
		return [val UTF8String];
	}
}

bool JsonArrayImpl::GetBoolAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val boolValue] != NO;
	}
}

int32_t JsonArrayImpl::GetInt32AtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val intValue];
	}
}

int64_t JsonArrayImpl::GetInt64AtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val longLongValue];
	}
}

uint32_t JsonArrayImpl::GetUInt32AtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return (uint32_t) [val unsignedLongValue];
	}
}

uint64_t JsonArrayImpl::GetUInt64AtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val unsignedLongLongValue];
	}
}

double JsonArrayImpl::GetDoubleAtIndex (int32_t idx) const {
	@autoreleasepool {
		NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return 0;
		}
		
		id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return 0;
		}
		
		NSNumber* val = (NSNumber*)item;
		return [val doubleValue];
	}
}

shared_ptr<JsonObject> JsonArrayImpl::GetObjectAtIndex (int32_t idx) const {
	@autoreleasepool {
		__weak NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return JsonObject::Create ();
		}
		
		__weak id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return JsonObject::Create ();
		}
		
		__weak NSMutableDictionary* val = (NSMutableDictionary*)item;
		return shared_ptr<JsonObject> (new JsonObjectImpl ((__bridge void*)val));
	}
}

shared_ptr<JsonArray> JsonArrayImpl::GetArrayAtIndex (int32_t idx) const {
	@autoreleasepool {
		__weak NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		if (idx < 0 || idx >= [arr count]) {
			return JsonArray::Create ();
		}
		
		__weak id item = [arr objectAtIndex:idx];
		if (item == nil) {
			return JsonArray::Create ();
		}
		
		__weak NSMutableArray* val = (NSMutableArray*)item;
		return shared_ptr<JsonArray> (new JsonArrayImpl ((__bridge void*)val));
	}
}

string JsonArrayImpl::ToString (bool prettyPrint) const {
	@autoreleasepool {
		NSError* err = nil;
		NSUInteger options = prettyPrint ? NSJSONWritingPrettyPrinted : 0;
		NSData* raw = [NSJSONSerialization dataWithJSONObject:(__bridge NSMutableArray*)mData options:options error:&err];
		if (raw == nil) { //Error
			return string ();
		}
		
		return [[[NSString alloc] initWithData:raw encoding:NSUTF8StringEncoding] UTF8String];
	}
}

vector<uint8_t> JsonArrayImpl::ToVector () const {
	@autoreleasepool {
		NSError* err = nil;
		NSData* raw = [NSJSONSerialization dataWithJSONObject:(__bridge NSMutableArray*)mData options:0 error:&err];
		if (raw == nil) { //Error
			return vector<uint8_t> ();
		}
		
		vector<uint8_t> buffer ([raw length]);
		[raw getBytes:&buffer[0] length:buffer.size()];
		return buffer;
	}
}

void JsonArrayImpl::IterateItems (function<bool (const string& value, int32_t idx, JsonDataType type)> handleItem) const {
	@autoreleasepool {
		__weak NSMutableArray* arr = (__bridge NSMutableArray*)mData;
		[arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			JsonDataType type = JsonDataType::Unknown;
			string jsonValue;
			if ([obj isKindOfClass:[NSString class]]) {
				type = JsonDataType::String;
				jsonValue = [(NSString*)obj UTF8String];
			} else if ([obj isKindOfClass:[NSNumber class]]) {
				const char* objCType = [obj objCType];
				if (strcmp (objCType, @encode (char)) == 0) {
					type = JsonDataType::Bool;
					jsonValue = [(NSNumber*)obj boolValue] ? "true" : "false";
				} else if (strcmp (objCType, @encode (int)) == 0) {
					type = JsonDataType::Int32;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (long long)) == 0) {
					type = JsonDataType::Int64;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (unsigned long)) == 0) {
					type = JsonDataType::UInt32;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (unsigned long long)) == 0) {
					type = JsonDataType::UInt64;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				} else if (strcmp (objCType, @encode (double)) == 0) {
					type = JsonDataType::Double;
					jsonValue = [[(NSNumber*)obj stringValue] UTF8String];
				}
			} else if ([obj isKindOfClass:[NSMutableArray class]]) {
				type = JsonDataType::Object;
				
				NSMutableDictionary* val = (NSMutableDictionary*)obj;
				jsonValue = JsonObjectImpl ((__bridge void*)val).ToString ();
			} else if ([obj isKindOfClass:[NSMutableDictionary class]]) {
				type = JsonDataType::Array;
				
				NSMutableArray* val = (NSMutableArray*)obj;
				jsonValue = JsonArrayImpl ((__bridge void*)val).ToString ();
			}
			
			if (type == JsonDataType::Unknown) { //Error
				return;
			}
			
			//Call the callback on each item
			if (!handleItem (jsonValue, (int32_t)idx, type)) {
				*stop = YES;
			}
		}];
	}
}
