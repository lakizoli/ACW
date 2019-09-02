#####################################################################
# Compile unwind as a static library

enable_language (C ASM)

add_library (
	NativeUnwind
	STATIC

	${CMAKE_CURRENT_LIST_DIR}/src/UnwindRegistersRestore.S
	${CMAKE_CURRENT_LIST_DIR}/src/UnwindRegistersSave.S
	${CMAKE_CURRENT_LIST_DIR}/src/libunwind.cpp
	${CMAKE_CURRENT_LIST_DIR}/src/Unwind-EHABI.cpp
	${CMAKE_CURRENT_LIST_DIR}/src/UnwindLevel1.c
	${CMAKE_CURRENT_LIST_DIR}/src/UnwindLevel1-gcc-ext.c
	${CMAKE_CURRENT_LIST_DIR}/src/Unwind-sjlj.c
)

include_directories (
	${CMAKE_CURRENT_LIST_DIR}/include/
	${CMAKE_CURRENT_LIST_DIR}/src/
)