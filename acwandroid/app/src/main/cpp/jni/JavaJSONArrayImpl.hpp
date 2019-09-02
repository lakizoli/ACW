#ifndef BIMX_JAVAJSONARRAYIMPL_H
#define BIMX_JAVAJSONARRAYIMPL_H

#include "JavaJSONBase.hpp"
#include "JsonDataType.hpp"
#include "JsonArray.hpp"
#include "JsonObject.hpp"

#include <memory>
#include <vector>

class JsonArrayImpl : public JsonArray, public JavaJSONBase {
    friend class JsonObjectImpl;
	friend class JsonArray;
    friend std::shared_ptr<JsonArray> JsonArray::Create ();

    explicit JsonArrayImpl (jobject internalObject);

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
    virtual bool HasBoolAtIndex (int32_t idx) const override;
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


#endif //BIMX_JAVAJSONARRAYIMPL_H
