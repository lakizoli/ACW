#ifndef BIMX_JAVAJSONBASE_H
#define BIMX_JAVAJSONBASE_H

#include <JavaObject.h>
#include "JsonDataType.hpp"

class JavaJSONBase : public JavaObject
{
protected:
	JsonDataType GetJSONDataType(JavaObject value) const ;
};


#endif //BIMX_JAVAJSONBASE_H
