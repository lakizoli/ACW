//
//  JsonImpl.hpp
//  Common
//
//  Created by Laki, Zoltan on 2017. 09. 20..
//  Copyright © 2017. ZApp. All rights reserved.
//

#ifndef JsonImpl_hpp
#define JsonImpl_hpp

#include "JsonDataType.hpp"
#include "JsonArray.hpp"
#include "JsonObject.hpp"

class JsonBase {
	friend class JsonObject;
	friend class JsonArray;

protected:
	void* mData; ///< NSMutableDictionary with values and keys of JSON object, or NSMutableArray with values of JSON array.

	explicit JsonBase (void* internalObject);
	JsonBase () : mData (nullptr) {}
	
	JsonBase (const JsonBase& src) = delete;
	JsonBase (JsonBase&& src) = delete;
	
	JsonBase& operator= (const JsonBase& src) = delete;
	JsonBase& operator= (JsonBase&& src) = delete;

	template<class ResultT, class ContainerT>
	static std::shared_ptr<ResultT> Parse (const ContainerT& jsonUTF8);

public:
	virtual ~JsonBase ();
};

class JsonObjectImpl : public JsonObject, public JsonBase {
	friend class JsonArrayImpl;
	friend class JsonBase;
	friend std::shared_ptr<JsonObject> JsonObject::Create ();

	explicit JsonObjectImpl (void* internalObject) : JsonBase (internalObject) {}
	JsonObjectImpl ();
	
	bool HasNumber (const std::string& key) const;

public:
	virtual ~JsonObjectImpl () {}
	
	JsonObjectImpl (const JsonObjectImpl& src) = delete;
	JsonObjectImpl (JsonObjectImpl&& src) = delete;
	
	JsonObjectImpl& operator= (const JsonObjectImpl& src) = delete;
	JsonObjectImpl& operator= (JsonObjectImpl&& src) = delete;
	
public:
	virtual void Add (const std::string& key, const char* value) override { Add (key, std::string (value)); }
	virtual void Add (const std::string& key, const std::string& value) override;
	virtual void Add (const std::string& key, bool value) override;
	virtual void Add (const std::string& key, int32_t value) override;
	virtual void Add (const std::string& key, int64_t value) override;
	virtual void Add (const std::string& key, uint32_t value) override;
	virtual void Add (const std::string& key, uint64_t value) override;
	virtual void Add (const std::string& key, double value) override;
	virtual void Add (const std::string& key, std::shared_ptr<JsonObject> value) override;
	virtual void Add (const std::string& key, std::shared_ptr<JsonArray> value) override;
	
	virtual bool HasString (const std::string& key) const override;
	virtual bool HasBool (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasInt32 (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasInt64 (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasUInt32 (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasUInt64 (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasDouble (const std::string& key) const override { return HasNumber (key); }
	virtual bool HasObject (const std::string& key) const override;
	virtual bool HasArray (const std::string& key) const override;
	
	virtual std::string GetString (const std::string& key) const override;
	virtual bool GetBool (const std::string& key) const override;
	virtual int32_t GetInt32 (const std::string& key) const override;
	virtual int64_t GetInt64 (const std::string& key) const override;
	virtual uint32_t GetUInt32 (const std::string& key) const override;
	virtual uint64_t GetUInt64 (const std::string& key) const override;
	virtual double GetDouble (const std::string& key) const override;
	virtual std::shared_ptr<JsonObject> GetObject (const std::string& key) const override;
	virtual std::shared_ptr<JsonArray> GetArray (const std::string& key) const override;
	
	virtual std::string ToString (bool prettyPrint = false) const override;
	virtual std::vector<uint8_t> ToVector () const override;

	virtual void IterateProperties (std::function<bool (const std::string& key, const std::string& value, JsonDataType type)> handleProperty) const override;
};

class JsonArrayImpl : public JsonArray, public JsonBase {
	friend class JsonObjectImpl;
	friend class JsonBase;
	friend std::shared_ptr<JsonArray> JsonArray::Create ();

	explicit JsonArrayImpl (void* internalObject) : JsonBase (internalObject) {}
	JsonArrayImpl ();
	
	bool HasNumberAtIndex (int32_t idx) const;

public:
	virtual ~JsonArrayImpl () {}
	
	JsonArrayImpl (const JsonArrayImpl& src) = delete;
	JsonArrayImpl (JsonArrayImpl&& src) = delete;
	
	JsonArrayImpl& operator = (const JsonArrayImpl& src) = delete;
	JsonArrayImpl& operator = (JsonArrayImpl&& src) = delete;
	
public:
	virtual void Add (const char* value) override { Add (std::string (value)); }
	virtual void Add (const std::string& value) override;
	virtual void Add (bool value) override;
	virtual void Add (int32_t value) override;
	virtual void Add (int64_t value) override;
	virtual void Add (uint32_t value) override;
	virtual void Add (uint64_t value) override;
	virtual void Add (double value) override;
	virtual void Add (std::shared_ptr<JsonObject> value) override;
	virtual void Add (std::shared_ptr<JsonArray> value) override;
	
	virtual int32_t GetCount () const override;
	
	virtual bool HasStringAtIndex (int32_t idx) const override;
	virtual bool HasBoolAtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasInt32AtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasInt64AtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasUInt32AtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasUInt64AtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasDoubleAtIndex (int32_t idx) const override { return HasNumberAtIndex (idx); }
	virtual bool HasObjectAtIndex (int32_t idx) const override;
	virtual bool HasArrayAtIndex (int32_t idx) const override;
	
	virtual std::string GetStringAtIndex (int32_t idx) const override;
	virtual bool GetBoolAtIndex (int32_t idx) const override;
	virtual int32_t GetInt32AtIndex (int32_t idx) const override;
	virtual int64_t GetInt64AtIndex (int32_t idx) const override;
	virtual uint32_t GetUInt32AtIndex (int32_t idx) const override;
	virtual uint64_t GetUInt64AtIndex (int32_t idx) const override;
	virtual double GetDoubleAtIndex (int32_t idx) const override;
	virtual std::shared_ptr<JsonObject> GetObjectAtIndex (int32_t idx) const override;
	virtual std::shared_ptr<JsonArray> GetArrayAtIndex (int32_t idx) const override;
	
	virtual std::string ToString (bool prettyPrint = false) const override;
	virtual std::vector<uint8_t> ToVector () const override;

	virtual void IterateItems (std::function<bool (const std::string& value, int32_t idx, JsonDataType type)> handleItem) const override;
};

#endif /* JsonImpl_hpp */
