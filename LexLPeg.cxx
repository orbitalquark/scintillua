/**
 * Lua-powered dynamic language lexer for Scintillua.
 * http://scintillua.googlecode.com
 *
 * Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net.
 * This file is distributed under Scintilla's license.
 *
 * Documentation can be found in the README, /lexers/lexer.lua, and
 * http://caladbolg.net/luadoc/textadept/modules/lexer.html.
 */

#if LPEG_LEXER || LPEG_LEXER_EXTERNAL

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ILexer.h"
#include "Scintilla.h"
#include "SciLexer.h"

#include "PropSetSimple.h"
#include "LexAccessor.h"
#include "LexerModule.h"

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
LUALIB_API int (luaopen_lpeg) (lua_State *L);
}

#ifdef __WIN32__
#define strcasecmp _stricmp
#endif

#define streq(s1, s2) (strcasecmp((s1), (s2)) == 0)

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

/**
 * Prints a Lua error message.
 * If an error message is not specified, the Lua error message at the top of the
 * stack is used and the stack is subsequently cleared.
 * @return false
 */
static bool l_error(lua_State *L, const char *str=NULL) {
	fprintf(stderr, "Lua Error: %s.\n", str ? str : lua_tostring(L, -1));
	lua_settop(L, 0);
	return false;
}

/**
 * Retrieves the style at a position.
 * Lua interface: StyleAt(pos)
 * @param pos The position to get the style for.
 */
static int lua_style_at(lua_State *L) {
	lua_getfield(L, LUA_REGISTRYINDEX, "pAccess");
	IDocument *pAccess = static_cast<IDocument *>(lua_touserdata(L, -1));
	LexAccessor styler(pAccess);
	int style = styler.StyleAt(luaL_checkinteger(L, 1) - 1);
	lua_getglobal(L, "_LEXER");
	lua_getfield(L, -1, "_TOKENS");
	lua_pushnil(L);
	while (lua_next(L, -2)) {
		// stylename = num
		if (luaL_checkinteger(L, -1) == style)
			break;
		else
			lua_pop(L, 1); // value
	}
	return 2;
}

/**
 * Gets an integer property value.
 * Lua interface: GetProperty(key [, default])
 * @param key The property key.
 * @param default Optional default value.
 * @return integer value of the property.
 */
static int lua_get_property(lua_State *L) {
	lua_getfield(L, LUA_REGISTRYINDEX, "props");
	PropSetSimple *props = static_cast<PropSetSimple *>(lua_touserdata(L, -1));
	lua_pushnumber(L, props->GetInt(luaL_checkstring(L, 1),
								 (lua_gettop(L) > 1) ? luaL_checkinteger(L, 2) : 0));
	return 1;
}

/**
 * Gets the fold level of a line number.
 * Lua interface: GetFoldLevel(line_number)
 * @param line_number The line number to get the fold level of.
 * @return the integer fold level.
 */
static int lua_get_fold_level(lua_State *L) {
	lua_getfield(L, LUA_REGISTRYINDEX, "pAccess");
	IDocument *pAccess = static_cast<IDocument *>(lua_touserdata(L, -1));
	lua_pushnumber(L, pAccess->GetLevel(luaL_checkinteger(L, 1)));
	return 1;
}

/**
 * Gets the indent amount of text on a specified line.
 * Lua interface: GetIndentAmount(line_number)
 * @param line_number The line number to get the indent amount of.
 */
static int lua_get_indent_amount(lua_State *L) {
	lua_getfield(L, LUA_REGISTRYINDEX, "pAccess");
	IDocument *pAccess = static_cast<IDocument *>(lua_touserdata(L, -1));
	lua_pushnumber(L, pAccess->GetLineIndentation(luaL_checkinteger(L, 1)));
	return 1;
}

#define l_openlib(f, s) \
	{ lua_pushcfunction(L, f); lua_pushstring(L, s); lua_call(L, 1, 0); }
#define l_setconst(c, s) \
	{ lua_pushnumber(L, c); lua_setfield(L, LUA_GLOBALSINDEX, s); }
#define SSS(m, l) if (SS && sci) SS(sci, m, style_num, l)

#ifndef NO_SCITE
#define RGB(c) ((c & 0xFF0000) >> 16) | (c & 0xFF00) | ((c & 0xFF) << 16)
#define PROPLEN 256
#endif

class LexerLPeg : public ILexer {
	lua_State *L;
	PropSetSimple props;
	SciFnDirect SS;
	sptr_t sci;
	bool reinit;
	bool multilang;
	int ws[STYLE_MAX + 1];
private:
	bool SetStyles() {
		lua_getglobal(L, "_LEXER");
		if (!lua_istable(L, -1)) return l_error(L, "'_LEXER' table not found");
		lua_getfield(L, -1, "_STYLES");
		if (!lua_istable(L, -1))
			return l_error(L, "'_LEXER._STYLES' table not found");
		bool cleared = false;
		lua_pushinteger(L, 32); // style_default
		lua_rawgeti(L, -2, 32);
		do {
			if (lua_isnumber(L, -2) && lua_istable(L, -1)) {
				int style_num = lua_tointeger(L, -2); // [num] = { properties }
#ifndef NO_SCITE
				char prop_name[PROPLEN], prop_str[PROPLEN], prop_part[PROPLEN];
				char *p = prop_str;
#endif
				lua_pushnil(L);
				while (lua_next(L, -2)) { // properties table
					const char *prop = lua_tostring(L, -2);
					if (streq(prop, "font")) {
						SSS(SCI_STYLESETFONT, reinterpret_cast<long>(lua_tostring(L, -1)));
#ifndef NO_SCITE
						sprintf(prop_part, "font:%s,", lua_tostring(L, -1));
#endif
					} else if (streq(prop, "size")) {
						SSS(SCI_STYLESETSIZE, static_cast<int>(lua_tointeger(L, -1)));
#ifndef NO_SCITE
						sprintf(prop_part, "size:%i,",
						        static_cast<int>(lua_tointeger(L, -1)));
#endif
					} else if (streq(prop, "bold")) {
						SSS(SCI_STYLESETBOLD, lua_toboolean(L, -1));
#ifndef NO_SCITE
						sprintf(prop_part, lua_toboolean(L, -1) ? "%s," : "not%s,", prop);
#endif
					} else if (streq(prop, "italic")) {
						SSS(SCI_STYLESETITALIC, lua_toboolean(L, -1));
#ifndef NO_SCITE
						sprintf(prop_part, lua_toboolean(L, -1) ? "%s," : "not%s,", prop);
#endif
					} else if (streq(prop, "underline")) {
						SSS(SCI_STYLESETUNDERLINE, lua_toboolean(L, -1));
#ifndef NO_SCITE
						sprintf(prop_part, lua_toboolean(L, -1) ? "%s," : "not%s,", prop);
#endif
					} else if (streq(prop, "fore")) {
						SSS(SCI_STYLESETFORE, static_cast<int>(lua_tointeger(L, -1)));
#ifndef NO_SCITE
						sprintf(prop_part, "fore:#%06X,",
						        RGB(static_cast<int>(lua_tointeger(L, -1))));
#endif
					} else if (streq(prop, "back")) {
						SSS(SCI_STYLESETBACK, static_cast<int>(lua_tointeger(L, -1)));
#ifndef NO_SCITE
						sprintf(prop_part, "back:#%06X,",
						        RGB(static_cast<int>(lua_tointeger(L, -1))));
#endif
					} else if (streq(prop, "eolfilled")) {
						SSS(SCI_STYLESETEOLFILLED, lua_toboolean(L, -1));
#ifndef NO_SCITE
						sprintf(prop_part, lua_toboolean(L, -1) ? "%s," : "not%s,", prop);
#endif
					} else if (streq(prop, "characterset")) {
						SSS(SCI_STYLESETCHARACTERSET,
						    static_cast<int>(lua_tointeger(L, -1)));
					} else if (streq(prop, "case")) {
						SSS(SCI_STYLESETCASE, static_cast<int>(lua_tointeger(L, -1)));
#ifndef NO_SCITE
						switch (lua_tointeger(L, -1)) {
							case 1: strcpy(prop_part, "case:u,\0"); break;
							case 2: strcpy(prop_part, "case:l,\0"); break;
							default: strcpy(prop_part, "case:m,\0"); break;
						}
#endif
					} else if (streq(prop, "visible")) {
						SSS(SCI_STYLESETVISIBLE, lua_toboolean(L, -1));
					} else if (streq(prop, "changeable")) {
						SSS(SCI_STYLESETCHANGEABLE, lua_toboolean(L, -1));
					} else if (streq(prop, "hotspot")) {
						SSS(SCI_STYLESETHOTSPOT, lua_toboolean(L, -1));
					}
#ifndef NO_SCITE
					if (p + strlen(prop_part) < prop_str + PROPLEN) {
						strcpy(p, prop_part);
						p += strlen(prop_part);
					}
#endif
					lua_pop(L, 1); // value
				}
				if (style_num == 32 && !cleared) {
					// Set all styles to style_default before loading individual ones.
					if (SS && sci) SS(sci, SCI_STYLECLEARALL, 0, 0);
					cleared = true;
					lua_pushnil(L);
					lua_replace(L, -3);
				}
#ifndef NO_SCITE
				sprintf(prop_name, "style.lpeg.%0d", style_num);
				*p = '\0';
				props.Set(prop_name, prop_str);
#endif
			} lua_pop(L, 1); // value
		} while (lua_next(L, -2)); // _STYLES table
		lua_pop(L, 2); // _LEXER._STYLES and _LEXER
		return true;
	}

	bool Init() {
		char p1[50], p2[FILENAME_MAX], p3[FILENAME_MAX], p4[FILENAME_MAX];
		props.GetExpanded("lexer.name", p1);
		props.GetExpanded("lexer.lpeg.home", p2);
		props.GetExpanded("lexer.lpeg.color.theme", p3);
		props.GetExpanded("lexer.lpeg.script", p4);
		if (*p1 == 0 || *p2 == 0 || *p3 == 0 || *p4 == 0) return false;

		// Initialize or reinitialize Lua.
		if (L) lua_close(L);
		L = lua_open();
		if (!L) {
			fprintf(stderr, "Lua failed to initialize.\n");
			return false;
		}

		// Set variables from properties.
		lua_pushstring(L, p1);
		lua_setfield(L, LUA_REGISTRYINDEX, "lexer_name");
		lua_pushstring(L, p2);
		lua_setglobal(L, "_LEXERHOME");
		lua_pushstring(L, p3);
		lua_setglobal(L, "_THEME");
		lua_pushstring(L, p4);
		lua_setfield(L, LUA_REGISTRYINDEX, "lexer_lua");

		// Set variables from platform.
#ifdef __WIN32__
		lua_pushboolean(L, 1);
		lua_setglobal(L, "WIN32");
#endif
#ifdef __OSX__
		lua_pushboolean(L, 1);
		lua_setglobal(L, "OSX");
#endif
#ifdef GTK
		lua_pushboolean(L, 1);
		lua_setglobal(L, "GTK");
#endif

		// Load Lua libraries.
		l_openlib(luaopen_base, "");
		l_openlib(luaopen_table, LUA_TABLIBNAME);
		l_openlib(luaopen_string, LUA_STRLIBNAME);
		l_openlib(luaopen_package, LUA_LOADLIBNAME);
		l_openlib(luaopen_lpeg, "lpeg");

		// Register functions.
		lua_register(L, "GetStyleAt", lua_style_at);
		lua_register(L, "GetProperty", lua_get_property);
		lua_register(L, "GetFoldLevel", lua_get_fold_level);
		lua_register(L, "GetIndentAmount", lua_get_indent_amount);

		// Register constants.
		l_setconst(SC_FOLDLEVELBASE, "SC_FOLDLEVELBASE");
		l_setconst(SC_FOLDLEVELWHITEFLAG, "SC_FOLDLEVELWHITEFLAG");
		l_setconst(SC_FOLDLEVELHEADERFLAG, "SC_FOLDLEVELHEADERFLAG");
		l_setconst(SC_FOLDLEVELNUMBERMASK, "SC_FOLDLEVELNUMBERMASK");

		// Load lexer.lua.
		lua_getfield(L, LUA_REGISTRYINDEX, "lexer_lua");
		const char *lexer_lua = lua_tostring(L, -1);
		lua_pop(L, 1); // lexer_lua
		if (strlen(lexer_lua) == 0) return false;
		if (luaL_dofile(L, lexer_lua) != 0) return l_error(L);

		// Load lexer tokens, styles, etc.
		lua_getglobal(L, "lexer");
		lua_getfield(L, -1, "load");
		if (lua_isfunction(L, -1)) {
			lua_getfield(L, LUA_REGISTRYINDEX, "lexer_name");
			if (lua_pcall(L, 1, 0, 0) != 0) return l_error(L);
		} else return l_error(L, "lexer.load not found");
		lua_pop(L, 1); // lexer

		// Setup Scintilla styles from loaded lexer styles.
		bool ok = SetStyles();
		if (!ok) return false;

		// If the lexer is a parent, it will have children in its _CHILDREN table.
		// If the lexer is a child, it will have a parent in its _TOKENRULES table.
		lua_getglobal(L, "_LEXER");
		lua_getfield(L, -1, "_CHILDREN");
		lua_getfield(L, -2, "_TOKENRULES");
		if (lua_istable(L, -1) || lua_istable(L, -2)) {
			multilang = true;
			// Determine which styles are language whitespace styles
			// ([lang]_whitespace). This is necessary for determining which language
			// to start lexing with.
			char style_name[50];
			for (int i = 1; i <= STYLE_MAX; i++) {
				PrivateCall(i, reinterpret_cast<void *>(style_name));
				ws[i] = strstr(style_name, "whitespace") ? 1 : 0;
			}
		}
		lua_pop(L, 3); // _LEXER._TOKENRULES, _LEXER._CHILDREN, and _LEXER

		reinit = false;
		return true;
	}

	void * StringResult(long lParam, const char *val) {
		const int n = strlen(val);
		if (lParam != 0) {
			char *ptr = reinterpret_cast<char *>(lParam);
			strcpy(ptr, val);
		}
		return reinterpret_cast<void *>(n); // Not including NUL
	}

public:
	LexerLPeg() : reinit(true), multilang(false) { L = 0; SS = 0; sci = 0; }
	~LexerLPeg() {}

	void SCI_METHOD Release() {
		if (L) lua_close(L);
		L = 0;
		delete this;
	}

	void SCI_METHOD Lex(unsigned int startPos, int lengthDoc, int initStyle,
	                    IDocument *pAccess) {
		if (reinit && !Init()) return;
		if (!L) return;
		lua_pushlightuserdata(L, reinterpret_cast<void *>(pAccess));
		lua_setfield(L, LUA_REGISTRYINDEX, "pAccess");
		LexAccessor styler(pAccess);

		// Start from the beginning of the current style so LPeg matches it.
		// For multilang lexers, start at whitespace since embedded languages have
		// [lang]_whitespace styles. This is so LPeg can start matching child
		// languages instead of parent ones if necessary.
		if (startPos > 0) {
			int i = startPos;
			while (i > 0 && styler.StyleAt(i - 1) == initStyle) i--;
			if (multilang) while (i > 0 && !ws[styler.StyleAt(i)]) i--;
			lengthDoc += startPos - i;
			startPos = i;
		}

		unsigned int startSeg = startPos, endSeg = startPos + lengthDoc;
		int style = 0;
		styler.StartAt(startPos, static_cast<char>(STYLE_MAX));
		styler.StartSegment(startPos);
		lua_getglobal(L, "lexer");
		lua_getfield(L, -1, "lex");
		if (lua_isfunction(L, -1)) {
			char *buf = const_cast<char *>(pAccess->BufferPointer());
			buf += startPos;
			lua_pushlstring(L, buf, lengthDoc);
			lua_pushinteger(L, styler.StyleAt(startPos));
			if (lua_pcall(L, 2, 1, 0) != 0) l_error(L);
			// Style the text from the token table returned.
			if (lua_istable(L, -1)) {
				lua_getglobal(L, "_LEXER");
				lua_pushstring(L, "_TOKENS");
				lua_rawget(L, -2);
				lua_remove(L, lua_gettop(L) - 1); // _LEXER
				lua_pushnil(L);
				while (lua_next(L, -3)) { // token (tokens[i])
					if (!lua_istable(L, -1)) {
						l_error(L, "Table of tokens expected from lexer.lex");
						break;
					}
					lua_rawgeti(L, -1, 1); // token[1]
					lua_rawget(L, -4); // _LEXER._TOKENS[token[1]]
					style = 32;
					if (!lua_isnil(L, -1)) style = lua_tointeger(L, -1);
					lua_pop(L, 1); // _LEXER._TOKENS[token[1]]
					lua_rawgeti(L, -1, 2); // token[2]
					unsigned int position = lua_tointeger(L, -1) - 1;
					lua_pop(L, 1); // token[2]
					lua_pop(L, 1); // token (tokens[i])
					if (style >= 0 && style <= STYLE_MAX)
						styler.ColourTo(startSeg + position - 1, style);
					else
						l_error(L, "Bad style number");
					if (position > endSeg) break;
				}
				lua_pop(L, 2); // _LEXER._TOKENS and token table returned
			} else l_error(L, "Table of tokens expected from lexer.lex");
		} else l_error(L, "lexer.lex not found");
		lua_pop(L, 1); // lexer
		styler.ColourTo(endSeg - 1, style);
		styler.Flush();
	}

	void SCI_METHOD Fold(unsigned int startPos, int lengthDoc, int initStyle,
	                     IDocument *pAccess) {
		if (reinit && !Init()) return;
		if (!L) return;
		lua_pushlightuserdata(L, reinterpret_cast<void *>(pAccess));
		lua_setfield(L, LUA_REGISTRYINDEX, "pAccess");
		lua_pushlightuserdata(L, reinterpret_cast<void *>(&props));
		lua_setfield(L, LUA_REGISTRYINDEX, "props");
		LexAccessor styler(pAccess);

		lua_getglobal(L, "lexer");
		lua_getfield(L, -1, "fold");
		if (lua_isfunction(L, -1)) {
			int currentLine = styler.GetLine(startPos);
			lua_pushlstring(L, pAccess->BufferPointer() + startPos, lengthDoc);
			lua_pushnumber(L, startPos);
			lua_pushnumber(L, currentLine);
			lua_pushnumber(L, styler.LevelAt(currentLine) & SC_FOLDLEVELNUMBERMASK);
			if (lua_pcall(L, 4, 1, 0) != 0) l_error(L);
			// Fold the text from the fold table returned.
			if (lua_istable(L, -1)) {
				lua_pushnil(L);
				int line = 0, level = 0, maxline = 0, maxlevel = 0;
				while (lua_next(L, -2)) { // fold (folds[i])
					if (!lua_istable(L, -1)) {
						l_error(L, "Table of folds expected from lexer.fold");
						break;
					}
					line = lua_tointeger(L, -2);
					lua_rawgeti(L, -1, 1); // fold[1]
					level = lua_tointeger(L, -1);
					lua_pop(L, 1); // fold[1]
					if (lua_objlen(L, -1) > 1) {
						lua_rawgeti(L, -1, 2); // fold[2]
						int flag = lua_tointeger(L, -1);
						level |= flag;
						lua_pop(L, 1); // fold[2]
					}
					styler.SetLevel(line, level);
					if (line > maxline) {
						maxline = line;
						maxlevel = level;
					}
					lua_pop(L, 1); // fold
				}
				lua_pop(L, 1); // fold table returned
				// Mask off the level number, leaving only the previous flags.
				int flagsNext = styler.LevelAt(maxline + 1) & ~SC_FOLDLEVELNUMBERMASK;
				styler.SetLevel(maxline + 1, maxlevel | flagsNext);
			} else l_error(L, "Table of folds expected from lexer.fold");
		} else l_error(L, "lexer.fold function not found");
		lua_pop(L, 1); // lexer
	}

	int SCI_METHOD Version() const { return 0; }
	const char * SCI_METHOD PropertyNames() { return ""; }
	int SCI_METHOD PropertyType(const char *name) { return 0; }
	const char * SCI_METHOD DescribeProperty(const char *name) { return ""; }
	int SCI_METHOD PropertySet(const char *key, const char *val) {
		props.Set(key, val);
		if (reinit) Init();
		return -1; // no need to re-lex
	}
	const char * SCI_METHOD DescribeWordListSets() { return ""; }
	int SCI_METHOD WordListSet(int n, const char *wl) { return -1; }

	void * SCI_METHOD PrivateCall(int code, void *arg) {
		long lParam = reinterpret_cast<long>(arg);
		const char *val = 0;
		switch(code) {
		case SCI_GETDIRECTFUNCTION:
			SS = reinterpret_cast<SciFnDirect>(reinterpret_cast<sptr_t>(arg));
			return NULL;
		case SCI_SETDOCPOINTER:
			sci = reinterpret_cast<sptr_t>(arg);
			return NULL;
		case SCI_SETLEXERLANGUAGE:
			char lexer_name[50];
			props.GetExpanded("lexer.name", lexer_name);
			if (strcmp(lexer_name, reinterpret_cast<const char *>(arg)) != 0) {
				reinit = true;
				PropertySet("lexer.name", reinterpret_cast<const char *>(arg));
			} else SetStyles(); // load styling information
			return NULL;
		case SCI_GETLEXERLANGUAGE:
			val = "null";
			if (L) {
				lua_getfield(L, LUA_REGISTRYINDEX, "lexer_name");
				val = lua_tostring(L, -1);
				lua_pop(L, 1); // lexer_name
			}
			return StringResult(lParam, val);
		default: // style-related
			if (code >= -STYLE_MAX && code < 0) { // retrieve SciTE style strings
#ifndef NO_SCITE
				char prop_str[PROPLEN];
				sprintf(prop_str, "style.lpeg.%0d", code + STYLE_MAX);
				return StringResult(lParam, props.Get(prop_str));
#else
				return NULL;
#endif
			} else if (code <= STYLE_MAX) { // retrieve style names
				val = "";
				if (L) {
					lua_getglobal(L, "_LEXER");
					if (lua_istable(L, -1)) {
						lua_getfield(L, -1, "_TOKENS");
						if (lua_istable(L, -1)) {
							lua_pushnil(L);
							while (lua_next(L, -2)) {
								// stylename = num
								if (luaL_checkinteger(L, -1) == static_cast<int>(code)) {
									val = lua_tostring(L, -2);
									lua_pop(L, 2); // value and key
									break;
								}
								lua_pop(L, 1); // value
							}
							lua_pop(L, 2); // _LEXER._TOKENS and _LEXER
						}
					}
				}
				return StringResult(lParam, strlen(val) ? val : "Not Available");
			} else return NULL;
		}
	}

	static ILexer *LexerFactoryLPeg() {
		return new LexerLPeg();
	}
};

#ifdef LPEG_LEXER_EXTERNAL
#ifdef __WIN32__
#define EXT_LEXER_DECL __declspec( dllexport ) __stdcall
#else
#define EXT_LEXER_DECL
#endif // __WIN32__
static const char *lexerName = "lpeg";
extern "C" {
int EXT_LEXER_DECL GetLexerCount() { return 1; }
void EXT_LEXER_DECL GetLexerName(unsigned int index, char *name, int len) {
	*name = 0;
	if ((index == 0) && (len > static_cast<int>(strlen(lexerName)))) {
		strcpy(name, lexerName);
	}
}
LexerFactoryFunction EXT_LEXER_DECL GetLexerFactory(unsigned int index) {
	if (index == 0)
		return LexerLPeg::LexerFactoryLPeg;
	else
		return 0;
}
}
/*
Forward the following properties from SciTE.
GetProperty "lexer.lpeg.home"
GetProperty "lexer.lpeg.color.theme"
GetProperty "lexer.lpeg.script"
GetProperty "fold.by.indentation"
*/
#else
LexerModule lmLPeg(SCLEX_AUTOMATIC - 1, LexerLPeg::LexerFactoryLPeg, "lpeg");
#endif // LPEG_LEXER_EXTERNAL

#endif // LPEG_LEXER || LPEG_LEXER_EXTERNAL
