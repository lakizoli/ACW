#####################################################################
# Compile NativeACW as a shared library

cmake_minimum_required (VERSION 3.4.1)

#####################################################################
# Dependencies

include (${CMAKE_CURRENT_LIST_DIR}/../../libunwind/compile_static_unwind.cmake)
#include (${CMAKE_CURRENT_LIST_DIR}/../../../PlatformConnector/Src.android/platformconnector/import_platformconnector.cmake)
#include (${CMAKE_CURRENT_LIST_DIR}/../../../Connector/Src.android/connector/import_connector.cmake)

###########################################################################
# NativeACW sources

add_library (
	NativeACW
	SHARED

	# Jni folder's source files
	src/main/cpp/main.cpp
	src/main/cpp/jni/jniapi.cpp
	src/main/cpp/jni/JavaArrays.cpp
	src/main/cpp/jni/JavaCallback.cpp
	src/main/cpp/jni/JavaContainers.cpp
	src/main/cpp/jni/JavaContext.cpp
	src/main/cpp/jni/JavaFile.cpp
	src/main/cpp/jni/JavaFunction.cpp
	src/main/cpp/jni/JavaString.cpp
	src/main/cpp/jni/JavaTypes.cpp
)

include_directories (
	src/main/cpp/
	src/main/cpp/jni
	../../libunwind/include
)

###########################################################################
# Link NativeACW dynamic library

target_link_libraries (
	NativeACW

	# dependencies
#	NativePlatformConnector
#	NativeConnector
)