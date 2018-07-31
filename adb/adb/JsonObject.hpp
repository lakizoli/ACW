//
//  JsonObject.hpp
//  Common
//
//  Created by Laki, Zoltan on 2017. 09. 20..
//  Copyright © 2017. ZApp. All rights reserved.
//

#ifndef JsonObject_hpp
#define JsonObject_hpp

#include "JsonDataType.hpp"

class JsonArray;

class JsonObject {
protected:
	JsonObject () {}
	
public:
	virtual ~JsonObject () {}
	
	static std::shared_ptr<JsonObject> Create ();

	static std::shared_ptr<JsonObject> Parse (const std::vector<uint8_t>& json);
	static std::shared_ptr<JsonObject> Parse (const std::string& json);

	JsonObject (const JsonObject& src) = delete;
	JsonObject (JsonObject&& src) = delete;
	
	JsonObject& operator= (const JsonObject& src) = delete;
	JsonObject& operator= (JsonObject&& src) = delete;

public:
	virtual void Add (const std::string& key, const char* value) = 0;
	virtual void Add (const std::string& key, const std::string& value) = 0;
	virtual void Add (const std::string& key, bool value) = 0;
	virtual void Add (const std::string& key, int32_t value) = 0;
	virtual void Add (const std::string& key, int64_t value) = 0;
	virtual void Add (const std::string& key, uint32_t value) = 0;
	virtual void Add (const std::string& key, uint64_t value) = 0;
	virtual void Add (const std::string& key, double value) = 0;
	virtual void Add (const std::string& key, std::shared_ptr<JsonObject> value) = 0;
	virtual void Add (const std::string& key, std::shared_ptr<JsonArray> value) = 0;
	
	virtual bool HasString (const std::string& key) const = 0;
	virtual bool HasBool (const std::string& key) const = 0;
	virtual bool HasInt32 (const std::string& key) const = 0;
	virtual bool HasInt64 (const std::string& key) const = 0;
	virtual bool HasUInt32 (const std::string& key) const = 0;
	virtual bool HasUInt64 (const std::string& key) const = 0;
	virtual bool HasDouble (const std::string& key) const = 0;
	virtual bool HasObject (const std::string& key) const = 0;
	virtual bool HasArray (const std::string& key) const = 0;
	
	virtual std::string GetString (const std::string& key) const = 0;
	virtual bool GetBool (const std::string& key) const = 0;
	virtual int32_t GetInt32 (const std::string& key) const = 0;
	virtual int64_t GetInt64 (const std::string& key) const = 0;
	virtual uint32_t GetUInt32 (const std::string& key) const = 0;
	virtual uint64_t GetUInt64 (const std::string& key) const = 0;
	virtual double GetDouble (const std::string& key) const = 0;
	virtual std::shared_ptr<JsonObject> GetObject (const std::string& key) const = 0;
	virtual std::shared_ptr<JsonArray> GetArray (const std::string& key) const = 0;
	
	virtual std::string ToString (bool prettyPrint = false) const = 0;
	virtual std::vector<uint8_t> ToVector () const = 0;
	
	virtual void IterateProperties (std::function<bool (const std::string& key, const std::string& value, JsonDataType type)> callback) const = 0;
};

#endif /* JsonObject_hpp */
