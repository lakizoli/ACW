#####################################################################
# Compile minizip as a static library

add_definitions (-DUSE_FILE32API)

find_library (
	z-lib
	z
)

add_library (
	NativeMiniZip
	STATIC

	${CMAKE_CURRENT_LIST_DIR}/minizip/ioapi.c
	${CMAKE_CURRENT_LIST_DIR}/minizip/miniunz.c
	${CMAKE_CURRENT_LIST_DIR}/minizip/minizip.c
	${CMAKE_CURRENT_LIST_DIR}/minizip/mztools.c
	${CMAKE_CURRENT_LIST_DIR}/minizip/unzip.c
	${CMAKE_CURRENT_LIST_DIR}/minizip/zip.c
)

include_directories (
	${CMAKE_CURRENT_LIST_DIR}/minizip/
)

target_link_libraries(
	NativeMiniZip

	${z-lib}
)