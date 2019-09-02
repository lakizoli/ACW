#include "JavaJSONBase.hpp"

JsonDataType JavaJSONBase::GetJSONDataType(JavaObject value) const
{
	JsonDataType type = JsonDataType::Unknown;
	if (value.IsInstanceOf ("java/lang/String")) {
		type = JsonDataType::String;
	} else if (value.IsInstanceOf ("java/lang/Boolean")) {
		type = JsonDataType::Bool;
	}
	if (value.IsInstanceOf ("java/lang/Number")) {
		if (value.IsInstanceOf ("java/lang/Integer")) {
			type = JsonDataType::Int32;
		} else if (value.IsInstanceOf ("java/lang/Long")) {
			type = JsonDataType::Int64;
			// No UInt64 detection possible, because that values are Doubles
		} else if (value.IsInstanceOf ("java/lang/Double")) {
			type = JsonDataType::Double;
		}
	} else if (value.IsInstanceOf ("org/json/JSONObject")) {
		type = JsonDataType::Object;
	} else if (value.IsInstanceOf ("org/json/JSONArray")) {
		type = JsonDataType::Array;
	}
	return type;
}
