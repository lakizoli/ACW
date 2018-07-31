//
//  JsonArray.hpp
//  Common
//
//  Created by Laki, Zoltan on 2017. 09. 20..
//  Copyright © 2017. ZApp. All rights reserved.
//

#ifndef JsonArray_hpp
#define JsonArray_hpp

#include "JsonDataType.hpp"

class JsonObject;

class JsonArray {
protected:
	JsonArray () {}
	
public:
	virtual ~JsonArray () {}
	
	static std::shared_ptr<JsonArray> Create ();

	static std::shared_ptr<JsonArray> Parse (const std::vector<uint8_t>& json);
	static std::shared_ptr<JsonArray> Parse (const std::string& json);
	
	JsonArray (const JsonArray& src) = delete;
	JsonArray (JsonArray&& src) = delete;
	
	JsonArray& operator = (const JsonArray& src) = delete;
	JsonArray& operator = (JsonArray&& src) = delete;

public:
	virtual void Add (const char* value) = 0;
	virtual void Add (const std::string& value) = 0;
	virtual void Add (bool value) = 0;
	virtual void Add (int32_t value) = 0;
	virtual void Add (int64_t value) = 0;
	virtual void Add (uint32_t value) = 0;
	virtual void Add (uint64_t value) = 0;
	virtual void Add (double value) = 0;
	virtual void Add (std::shared_ptr<JsonObject> value) = 0;
	virtual void Add (std::shared_ptr<JsonArray> value) = 0;
	
	virtual int32_t GetCount () const = 0;
	
	virtual bool HasStringAtIndex (int32_t idx) const = 0;
	virtual bool HasBoolAtIndex (int32_t idx) const = 0;
	virtual bool HasInt32AtIndex (int32_t idx) const = 0;
	virtual bool HasInt64AtIndex (int32_t idx) const = 0;
	virtual bool HasUInt32AtIndex (int32_t idx) const = 0;
	virtual bool HasUInt64AtIndex (int32_t idx) const = 0;
	virtual bool HasDoubleAtIndex (int32_t idx) const = 0;
	virtual bool HasObjectAtIndex (int32_t idx) const = 0;
	virtual bool HasArrayAtIndex (int32_t idx) const = 0;
	
	virtual std::string GetStringAtIndex (int32_t idx) const = 0;
	virtual bool GetBoolAtIndex (int32_t idx) const = 0;
	virtual int32_t GetInt32AtIndex (int32_t idx) const = 0;
	virtual int64_t GetInt64AtIndex (int32_t idx) const = 0;
	virtual uint32_t GetUInt32AtIndex (int32_t idx) const = 0;
	virtual uint64_t GetUInt64AtIndex (int32_t idx) const = 0;
	virtual double GetDoubleAtIndex (int32_t idx) const = 0;
	virtual std::shared_ptr<JsonObject> GetObjectAtIndex (int32_t idx) const = 0;
	virtual std::shared_ptr<JsonArray> GetArrayAtIndex (int32_t idx) const = 0;
	
	virtual std::string ToString (bool prettyPrint = false) const = 0;
	virtual std::vector<uint8_t> ToVector () const = 0;

	virtual void IterateItems (std::function<bool (const std::string& value, int32_t idx, JsonDataType type)> handleItem) const = 0;
};

#endif /* JsonArray_hpp */
