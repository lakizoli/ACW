#ifndef BIMX_CMNJSONIMPL_H
#define BIMX_CMNJSONIMPL_H

#include "JsonDataType.hpp"
#include "JsonArray.hpp"
#include "JsonObject.hpp"
#include "JavaJSONBase.hpp"

#include <memory>
#include <vector>

//class JsonBase : public JavaObject{
//	friend class JsonObject;
//	friend class JsonArray;
//
//protected:
//
//	explicit JsonBase (jobject internalObject);
//	JsonBase ();
//
//	JsonBase (const JsonBase& src) = delete;
//	JsonBase (JsonBase&& src) = delete;
//
//	JsonBase& operator= (const JsonBase& src) = delete;
//	JsonBase& operator= (JsonBase&& src) = delete;
//
//	template<class ResultT>
//	static std::shared_ptr<ResultT> Parse (const std::string& jsonUTF8);
//
//public:
//	virtual ~JsonBase ();
//};

class JsonObjectImpl : public JsonObject, public JavaJSONBase {
	friend class JsonArrayImpl;
	friend class JsonObject;
	friend std::shared_ptr<JsonObject> JsonObject::Create ();
	
	explicit JsonObjectImpl (jobject internalObject);

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
	virtual bool HasBool (const std::string& key) const override;
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


#endif //BIMX_CMNJSONIMPL_H
