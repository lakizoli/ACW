#####################################################################
# Compile NativeACW as a shared library

cmake_minimum_required (VERSION 3.4.1)

#####################################################################
# Dependencies

include (${CMAKE_CURRENT_LIST_DIR}/../../libunwind/compile_static_unwind.cmake)
include (${CMAKE_CURRENT_LIST_DIR}/../../sqlite3/compile_static_sqlite3.cmake)
include (${CMAKE_CURRENT_LIST_DIR}/../../minizip/compile_static_minizip.cmake)

find_library (
	log-lib
	log
)

###########################################################################
# NativeACW sources

add_library (
	NativeACW
	SHARED

	# Jni folder's source files
	src/main/cpp/FileUtils.cpp
	src/main/cpp/main.cpp
	src/main/cpp/SavedCrossword.cpp
	src/main/cpp/PackageManager.cpp
	src/main/cpp/jni/jniapi.cpp
	src/main/cpp/jni/JavaArrays.cpp
	src/main/cpp/jni/JavaCallback.cpp
	src/main/cpp/jni/JavaContainers.cpp
	src/main/cpp/jni/JavaContext.cpp
	src/main/cpp/jni/JavaFile.cpp
	src/main/cpp/jni/JavaFunction.cpp
	src/main/cpp/jni/JavaString.cpp
	src/main/cpp/jni/JavaTypes.cpp
	src/main/cpp/jni/JavaJSONBase.cpp
	src/main/cpp/jni/JavaJSONArrayImpl.cpp
	src/main/cpp/jni/JavaJSONObjectImpl.cpp

	# adb library
	../../adb/adb/DBHandler.cpp
	../../adb/adb/BasicInfo.cpp
	../../adb/adb/CardList.cpp
	../../adb/adb/UsedWords.cpp

	# cw library
	../../cw/cw/Crossword.cpp
	../../cw/cw/Generator.cpp
	../../cw/cw/Grid.cpp
	../../cw/cw/Cell.cpp
	../../cw/cw/QuestionInfo.cpp
	../../cw/cw/WordBank.cpp
)

include_directories (
	src/main/cpp/
	src/main/cpp/jni
	../../libunwind/include
	../../cw/cw
	../../adb/adb
)

###########################################################################
# Link NativeACW dynamic library

target_link_libraries (
	NativeACW

	# dependencies
	${log-lib}
	NativeUnwind
	NativeSQLite3
	NativeMiniZip
)