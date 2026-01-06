# Copyright 2025-2026 Mitchell. See LICENSE.

cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(APPLE)
	set(CMAKE_OSX_DEPLOYMENT_TARGET 11 CACHE STRING "")
endif()

set(src ${CMAKE_SOURCE_DIR})

project(scintillua LANGUAGES C CXX)

# Dependencies.
include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
set(deps_dir ${CMAKE_BINARY_DIR}/_deps)
function(fetch name url)
	string(REGEX MATCH "[^/]+$" archive ${url})
	if(EXISTS ${deps_dir}/${archive})
		set(url file://${deps_dir}/${archive}) # use local archive instead of downloading
	endif()
	FetchContent_Declare(${name} URL ${url})
	# Note: cannot FetchContent_MakeAvailable(${name}) here, as name must be a literal.
endfunction()
fetch(scintilla https://www.scintilla.org/scintilla501.tgz)
fetch(lexilla https://www.scintilla.org/lexilla510.tgz)
fetch(lua http://www.lua.org/ftp/lua-5.3.5.tar.gz) # needs to be same X.Y as SciTE
fetch(lpeg http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.1.0.tar.gz)
FetchContent_MakeAvailable(scintilla lexilla lua lpeg)
set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL "Do not update deps if already set up")

# Scintilla.
# Nothing to set up.

# Lexilla.
add_library(lexilla STATIC)
set(lexilla_src lexlib/PropSetSimple.cxx lexlib/Accessor.cxx lexlib/DefaultLexer.cxx)
list(TRANSFORM lexilla_src PREPEND ${lexilla_SOURCE_DIR}/)
target_sources(lexilla PRIVATE ${lexilla_src})
target_include_directories(lexilla PUBLIC ${scintilla_SOURCE_DIR}/include
	${lexilla_SOURCE_DIR}/include ${lexilla_SOURCE_DIR}/lexlib)
target_compile_definitions(lexilla PUBLIC SCI_LEXER)
set_property(TARGET lexilla PROPERTY POSITION_INDEPENDENT_CODE ON)

# Lua.
add_library(lua STATIC)
file(GLOB lua_src ${lua_SOURCE_DIR}/src/*.c)
list(FILTER lua_src EXCLUDE REGEX
	"(lua|luac|lbitlib|lcorolib|ldblib|liolib|loadlib|loslib|linit)\.c$")
target_include_directories(lua PUBLIC ${lua_SOURCE_DIR}/src)
target_sources(lua PRIVATE ${lua_src})
target_compile_definitions(lua PRIVATE $<$<CONFIG:Debug>:LUA_USE_APICHECK>)
set_property(TARGET lua PROPERTY POSITION_INDEPENDENT_CODE ON)

# LPeg.
add_library(lpeg STATIC)
file(GLOB lpeg_src ${lpeg_SOURCE_DIR}/*.c)
target_sources(lpeg PRIVATE ${lpeg_src})
target_link_libraries(lpeg PRIVATE lua)
set_property(TARGET lpeg PROPERTY POSITION_INDEPENDENT_CODE ON)

# Scintillua.
set(scintillua_src ${src}/Scintillua.cxx)
add_library(scintillua SHARED ${scintillua_src})
target_link_libraries(scintillua PRIVATE lexilla lua lpeg)

# Install.
install(TARGETS scintillua DESTINATION ${src}/lexers)
