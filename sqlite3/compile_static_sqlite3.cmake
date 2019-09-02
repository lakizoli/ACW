#####################################################################
# Compile sqlite3 as a static library

add_library (
	NativeSQLite3
	STATIC

	${CMAKE_CURRENT_LIST_DIR}/sqlite3/sqlite3.c
)

include_directories (
	${CMAKE_CURRENT_LIST_DIR}/sqlite3/
)