/**
 * Copyright 2006-2013 Mitchell mitchell.att.foicica.com.
 * This file is distributed under Scintilla's license.
 *
 * Lua-powered dynamic language lexer for Scintillua.
 * http://foicica.com/scintillua
 *
 * For documentation on writing lexers, see *lexers/lexer.lua*.
 */

#if LPEG_LEXER || LPEG_LEXER_EXTERNAL

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef CURSES
#include <curses.h>
#endif

#include "ILexer.h"
#include "Scintilla.h"
#include "SciLexer.h"

#include "PropSetSimple.h"
#include "LexAccessor.h"
#include "LexerModule.h"

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
LUALIB_API int (luaopen_lpeg) (lua_State *L);
}

#ifdef _WIN32
#define strcasecmp _stricmp
#endif
#define streq(s1, s2) (strcasecmp((s1), (s2)) == 0)

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

#define l_setmetatable(l, k, mtf) { \
	if (luaL_newmetatable(l, k)) { \
		lua_pushcfunction(l, mtf), lua_setfield(l, -2, "__index"); \
		lua_pushcfunction(l, mtf), lua_setfield(l, -2, "__newindex"); \
	} \
	lua_setmetatable(l, -2); \
}
#define l_pushlexerp(l, mtf) { \
	lua_newtable(l); \
	lua_pushvalue(l, 2), lua_setfield(l, -2, "property"); \
	l_setmetatable(l, "sci_lexerp", mtf); \
}
#if LUA_VERSION_NUM < 502
#define l_openlib(f, s) \
	(lua_pushcfunction(L, f), lua_pushstring(L, s), lua_call(L, 1, 0))
#define LUA_BASELIBNAME ""
#define lua_rawlen lua_objlen
#define LUA_OK 0
#define lua_compare(l, a, b, _) lua_equal(l, a, b)
#define LUA_OPEQ 0
#else
#define l_openlib(f, s) (luaL_requiref(L, s, f, 1), lua_pop(L, 1))
#define LUA_BASELIBNAME "_G"
#endif
#define l_setconstant(l, c, k) (lua_pushnumber(l, c), lua_setfield(l, -2, k))

#ifdef CURSES
#define A_COLORCHAR (A_COLOR | A_CHARTEXT)
#endif

/** The LPeg Scintilla lexer. */
class LexerLPeg : public ILexer {
	/**
	 * The lexer's Lua state.
	 * It is cleared each time the lexer language changes.
	 */
	lua_State *L;
	/**
	 * The set of properties for the lexer.
	 * The `lexer.name`, `lexer.lpeg.home`, and `lexer.lpeg.color.theme`
	 * properties must be defined before running the lexer.
	 * For use with SciTE, all of the style property strings generated for the
	 * current lexer are placed in here.
	 */
	PropSetSimple props;
	/** The function to send Scintilla messages with. */
	SciFnDirect SS;
	/** The Scintilla object the lexer belongs to. */
	sptr_t sci;
	/**
	 * The flag indicating whether or not the lexer needs to be re-initialized.
	 * Re-initialization is required after the lexer language changes.
	 */
	bool reinit;
	/**
	 * The flag indicating whether or not the lexer language has embedded lexers.
	 */
	bool multilang;
	/**
	 * The list of style numbers considered to be whitespace styles.
	 * This is used in multi-language lexers when backtracking to whitespace to
	 * determine which lexer grammar to use.
	 */
	bool ws[STYLE_MAX + 1];

	/**
	 * Prints the given message or a Lua error message and clears the stack.
	 * @param str The error message to print. If `NULL`, prints the Lua error
	 *   message at the top of the stack.
	 * @return false
	 */
	static bool l_error(lua_State *L, const char *str=NULL) {
		fprintf(stderr, "Lua Error: %s.\n", str ? str : lua_tostring(L, -1));
		lua_settop(L, 0);
		return false;
	}

	/** `lexer.__index` Lua metatable. */
	static int llexer_property(lua_State *L) {
		int newindex = (lua_gettop(L) == 3);
		luaL_getmetatable(L, "sci_lexer");
		lua_getmetatable(L, 1); // metatable can be either sci_lexer or sci_lexerp
		int is_lexer = lua_compare(L, -1, -2, LUA_OPEQ);
		lua_pop(L, 2); // metatable, metatable

		lua_getfield(L, LUA_REGISTRYINDEX, "sci_buffer");
		IDocument *buffer = static_cast<IDocument *>(lua_touserdata(L, -1));
		lua_getfield(L, LUA_REGISTRYINDEX, "sci_props");
		PropSetSimple *props = static_cast<PropSetSimple *>(lua_touserdata(L, -1));
		lua_pop(L, 2); // sci_buffer and sci_props

		is_lexer ? lua_pushvalue(L, 2) // key is given
		         : lua_getfield(L, 1, "property"); // indexible property
		const char *key = lua_tostring(L, -1);
		if (strcmp(key, "fold_level") == 0) {
			luaL_argcheck(L, !newindex, 3, "read-only property");
			if (is_lexer) {
				l_pushlexerp(L, llexer_property);
			} else lua_pushnumber(L, buffer->GetLevel(luaL_checkinteger(L, 2)));
		} else if (strcmp(key, "indent_amount") == 0) {
			luaL_argcheck(L, !newindex, 3, "read-only property");
			if (is_lexer) {
				l_pushlexerp(L, llexer_property);
			} else
				lua_pushnumber(L, buffer->GetLineIndentation(luaL_checkinteger(L, 2)));
		} else if (strcmp(key, "property") == 0) {
			luaL_argcheck(L, !is_lexer || !newindex, 3, "read-only property");
			if (is_lexer) {
				l_pushlexerp(L, llexer_property);
			} else if (!newindex)
				lua_pushstring(L, props->Get(luaL_checkstring(L, 2)));
			else
				props->Set(luaL_checkstring(L, 2), luaL_checkstring(L, 3));
		} else if (strcmp(key, "property_int") == 0) {
			luaL_argcheck(L, !newindex, 3, "read-only property");
			if (is_lexer) {
				l_pushlexerp(L, llexer_property);
			} else {
				lua_pushstring(L, props->Get(luaL_checkstring(L, 2)));
				lua_pushnumber(L, lua_tonumber(L, -1));
			}
		} else if (strcmp(key, "style_at") == 0) {
			luaL_argcheck(L, !newindex, 3, "read-only property");
			if (is_lexer) {
				l_pushlexerp(L, llexer_property);
			} else {
				int style = buffer->StyleAt(luaL_checkinteger(L, 2) - 1);
				lua_getglobal(L, "_LEXER"), lua_getfield(L, -1, "_TOKENS");
				lua_pushnil(L);
				while (lua_next(L, -2)) { // style_name = style_num
					if (luaL_checkinteger(L, -1) == style) break;
					lua_pop(L, 1); // value
				}
				lua_pop(L, 1); // style_num
			}
		} else !newindex ? lua_rawget(L, 1) : lua_rawset(L, 1);
		return 1;
	}

	/**
	 * Expands value of the string property key at index *index* and pushes the
	 * result onto the stack.
	 * @param L The Lua State.
	 * @param index The index the string property key.
	 */
	void lL_getexpanded(lua_State *L, int index) {
		lua_getglobal(L, "lexer");
		lua_getfield(L, -1, "property_expanded");
		lua_pushvalue(L, (index > 0) ? index : index - 2);
		lua_gettable(L, -2);
		lua_remove(L, -2), lua_remove(L, -2); // lexer, property_expanded
	}

	/**
	 * Parses the given style string to set the properties for the given style
	 * number.
	 * @param num The style number to set properties for.
	 * @param style The style string containing properties to set.
	 */
	void SetStyle(int num, const char *style) {
		char *option = const_cast<char *>(style);
		while (option) {
			char *next = strchr(option, ',');
			if (next) *next++ = '\0';
			char *p = strchr(option, ':');
			if (p) *p++ = '\0';
			if (streq(option, "font"))
				SS(sci, SCI_STYLESETFONT, num, reinterpret_cast<sptr_t>(p));
			else if (streq(option, "size"))
				SS(sci, SCI_STYLESETSIZE, num, static_cast<int>(atoi(p)));
			else if (streq(option, "bold") || streq(option, "notbold")) {
#ifndef CURSES
				SS(sci, SCI_STYLESETBOLD, num, *option == 'b');
#else
				// Scinterm requires font attributes to be stored in the "font weight"
				// style attribute.
				// First, clear any existing SC_WEIGHT_NORMAL, SC_WEIGHT_SEMIBOLD, or
				// SC_WEIGHT_BOLD values stored in the lower 16 bits. Then set the
				// appropriate curses attr.
				sptr_t weight = SS(sci, SCI_STYLEGETWEIGHT, num, 0) & ~A_COLORCHAR;
				if (*option == 'b')
					SS(sci, SCI_STYLESETWEIGHT, num, weight | A_BOLD);
				else
					SS(sci, SCI_STYLESETWEIGHT, num, weight & ~A_BOLD);
#endif
			} else if (streq(option, "italics") || streq(option, "notitalics"))
				SS(sci, SCI_STYLESETITALIC, num, *option == 'i');
			else if (streq(option, "underlined") || streq(option, "notunderlined")) {
#ifndef CURSES
				SS(sci, SCI_STYLESETUNDERLINE, num, *option == 'u');
#else
				// Scinterm requires font attributes to be stored in the "font weight"
				// style attribute.
				// First, clear any existing SC_WEIGHT_NORMAL, SC_WEIGHT_SEMIBOLD, or
				// SC_WEIGHT_BOLD values stored in the lower 16 bits. Then set the
				// appropriate curses attr.
				sptr_t weight = SS(sci, SCI_STYLEGETWEIGHT, num, 0) & ~A_COLORCHAR;
				if (*option == 'u')
					SS(sci, SCI_STYLESETWEIGHT, num, weight | A_UNDERLINE);
				else
					SS(sci, SCI_STYLESETWEIGHT, num, weight & ~A_UNDERLINE);
#endif
			} else if (streq(option, "fore")) {
				int base = 0;
				if (*p == '#') p++, base = 16; // #RRGGBB format
				SS(sci, SCI_STYLESETFORE, num, static_cast<int>(strtol(p, NULL, base)));
			} else if (streq(option, "back")) {
				int base = 0;
				if (*p == '#') p++, base = 16; // #RRGGBB format
				SS(sci, SCI_STYLESETBACK, num, static_cast<int>(strtol(p, NULL, base)));
			} else if (streq(option, "eolfilled") || streq(option, "noteolfilled"))
				SS(sci, SCI_STYLESETEOLFILLED, num, *option == 'e');
			else if (streq(option, "characterset"))
				SS(sci, SCI_STYLESETCHARACTERSET, num, static_cast<int>(atoi(p)));
			else if (streq(option, "case") && p) {
				if (*p == 'u')
					SS(sci, SCI_STYLESETCASE, num, SC_CASE_UPPER);
				else if (*p == 'l')
					SS(sci, SCI_STYLESETCASE, num, SC_CASE_LOWER);
			} else if (streq(option, "visible") || streq(option, "notvisible"))
				SS(sci, SCI_STYLESETVISIBLE, num, *option == 'v');
			else if (streq(option, "changeable") || streq(option, "notchangeable"))
				SS(sci, SCI_STYLESETCHANGEABLE, num, *option == 'c');
			else if (streq(option, "hotspot") || streq(option, "nothotspot"))
				SS(sci, SCI_STYLESETHOTSPOT, num, *option == 'h');
			option = next;
		}
	}

	/**
	 * Iterates through `_LEXER._TOKENS`, setting the style properties for all
	 * defined styles, or for SciTE, generates the set of style properties instead
	 * of directly setting style properties.
	 */
	bool SetStyles() {
		lua_getglobal(L, "_LEXER");
		if (!lua_istable(L, -1)) return l_error(L, "'_LEXER' table not found");
		lua_getfield(L, -1, "_TOKENS");
		if (!lua_istable(L, -1))
			return l_error(L, "'_LEXER._TOKENS' table not found");
#ifdef NO_SCITE
		if (!SS || !sci) return true; // skip, but do not report an error
		lua_pushstring(L, "style.default"), lL_getexpanded(L, -1);
		SetStyle(STYLE_DEFAULT, lua_tostring(L, -1));
		lua_pop(L, 2); // style and "style.default"
		SS(sci, SCI_STYLECLEARALL, 0, 0); // set default styles
		lua_pushnil(L);
		while (lua_next(L, -2)) {
			if (lua_isstring(L, -2) && lua_isnumber(L, -1) &&
			    lua_tointeger(L, -1) != STYLE_DEFAULT) {
				lua_pushstring(L, "style."), lua_pushvalue(L, -3), lua_concat(L, 2);
				lL_getexpanded(L, -1), lua_replace(L, -2);
				SetStyle(lua_tointeger(L, -2), lua_tostring(L, -1));
				lua_pop(L, 1); // style
			}
			lua_pop(L, 1); // value
		}
#else
		char prop_name[32];
		lua_pushnil(L);
		while (lua_next(L, -2)) {
			if (lua_isstring(L, -2) && lua_isnumber(L, -1)) {
				sprintf(prop_name, "style.lpeg.%0d",
				        static_cast<int>(lua_tointeger(L, -1)));
				lua_pushstring(L, "style."), lua_pushvalue(L, -3), lua_concat(L, 2);
				lL_getexpanded(L, -1), lua_replace(L, -2);
				props.Set(prop_name, lua_tostring(L, -1));
				lua_pop(L, 1); // style
			}
			lua_pop(L, 1); // value
		}
#endif
		lua_pop(L, 2); // _LEXER._TOKENS and _LEXER
		return true;
	}

	/**
	 * Returns the style name for the given style number.
	 * @param style The style number to get the style name for.
	 * @return style name or NULL
	 */
	const char *GetStyleName(int style) {
		const char *name = NULL;
		if (L) {
			lua_getglobal(L, "_LEXER");
			if (lua_istable(L, -1)) {
				lua_getfield(L, -1, "_TOKENS");
				if (lua_istable(L, -1)) {
					lua_pushnil(L);
					while (lua_next(L, -2)) { // style_name = style_num
						if (lua_tointeger(L, -1) == style) {
							name = lua_tostring(L, -2);
							lua_pop(L, 2); // value and key
							break;
						}
						lua_pop(L, 1); // value
					}
				}
				lua_pop(L, 1); // _LEXER._TOKENS
			}
			lua_pop(L, 1); // _LEXER
		}
		return name;
	}

	/**
	 * Initializes the lexer once the `lexer.lpeg.home` and `lexer.name`
	 * properties are set.
	 */
	bool Init() {
		char home[FILENAME_MAX], lexer[50], theme[FILENAME_MAX];
		props.GetExpanded("lexer.lpeg.home", home);
		props.GetExpanded("lexer.name", lexer);
		props.GetExpanded("lexer.lpeg.color.theme", theme);
		if (*home == '\0' || *lexer == '\0') return false;

		if (L) lua_close(L);
		if (!(L = luaL_newstate()))
			return (fprintf(stderr, "Lua failed to initialize.\n"), false);
		l_openlib(luaopen_base, LUA_BASELIBNAME);
		l_openlib(luaopen_table, LUA_TABLIBNAME);
		l_openlib(luaopen_string, LUA_STRLIBNAME);
		l_openlib(luaopen_package, LUA_LOADLIBNAME);
		lua_getglobal(L, "package");
		lua_pushstring(L, home), lua_pushstring(L, "/?.lua"), lua_concat(L, 2);
		lua_setfield(L, -2, "path"), lua_pop(L, 1); // package
		l_openlib(luaopen_lpeg, "lpeg");

#ifdef _WIN32
		lua_pushboolean(L, 1), lua_setglobal(L, "WIN32");
#endif
#ifdef __APPLE__
		lua_pushboolean(L, 1), lua_setglobal(L, "OSX");
#endif
#ifdef GTK
		lua_pushboolean(L, 1), lua_setglobal(L, "GTK");
#endif
#ifdef CURSES
		lua_pushboolean(L, 1), lua_setglobal(L, "CURSES");
#endif
		lua_pushlightuserdata(L, reinterpret_cast<void *>(&props));
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_props");
		lua_pushstring(L, lexer);
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_lexer_name");

		if (luaL_dostring(L, "lexer=require'lexer'") != LUA_OK) return l_error(L);
		lua_getglobal(L, "lexer");
		l_setconstant(L, SC_FOLDLEVELBASE, "FOLD_BASE");
		l_setconstant(L, SC_FOLDLEVELWHITEFLAG, "FOLD_BLANK");
		l_setconstant(L, SC_FOLDLEVELHEADERFLAG, "FOLD_HEADER");
		l_setmetatable(L, "sci_lexer", llexer_property);
		if (*theme) {
			if (!(strstr(theme, "/") || strstr(theme, "\\"))) { // theme name
				lua_pushstring(L, home);
				lua_pushstring(L, "/themes/");
				lua_pushstring(L, theme);
				lua_pushstring(L, ".lua");
				lua_concat(L, 4);
			} else lua_pushstring(L, theme); // path to theme
			if (luaL_dofile(L, lua_tostring(L, -1)) != LUA_OK) return l_error(L);
		}
		lua_settop(L, 0); // pop results from dostring and dofile

		lua_getglobal(L, "lexer"), lua_getfield(L, -1, "load");
		if (lua_isfunction(L, -1)) {
			lua_getfield(L, LUA_REGISTRYINDEX, "sci_lexer_name");
			if (lua_pcall(L, 1, 0, 0) != LUA_OK) return l_error(L);
		} else return l_error(L, "'lexer.load' function not found");
		lua_pop(L, 1); // lexer
		if (!SetStyles()) return false;

		// If the lexer is a parent, it will have children in its _CHILDREN table.
		// If the lexer is a child, it will have a parent in its _TOKENRULES table.
		lua_getglobal(L, "_LEXER");
		lua_getfield(L, -1, "_CHILDREN"), lua_getfield(L, -2, "_TOKENRULES");
		if (lua_istable(L, -1) || lua_istable(L, -2)) {
			multilang = true;
			// Determine which styles are language whitespace styles
			// ([lang]_whitespace). This is necessary for determining which language
			// to start lexing with.
			char style_name[50];
			for (int i = 0; i <= STYLE_MAX; i++) {
				PrivateCall(i, reinterpret_cast<void *>(style_name));
				ws[i] = strstr(style_name, "whitespace") ? true : false;
			}
		}
		lua_pop(L, 3); // _LEXER._TOKENRULES, _LEXER._CHILDREN, and _LEXER

		reinit = false;
		return true;
	}

	/**
	 * When *lparam* is `0`, returns the size of the buffer needed to store the
	 * given string *str* in; otherwise copies *str* into the buffer *lparam* and
	 * returns the number of bytes copied.
	 * @param lparam `0` to get the number of bytes needed to store *str* or a
	 *   pointer to a buffer large enough to copy *str* into.
	 * @param str The string to copy.
	 * @return number of bytes needed to hold *str*
	 */
	void *StringResult(long lparam, const char *str) {
		if (lparam) strcpy(reinterpret_cast<char *>(lparam), str);
		return reinterpret_cast<void *>(strlen(str));
	}

public:
	/** Constructor. */
	LexerLPeg() : reinit(true), multilang(false) { L = NULL, SS = NULL, sci = 0; }
	/** Destructor. */
	~LexerLPeg() {}

	/** Destroys the lexer object. */
	void SCI_METHOD Release() {
		if (L) lua_close(L), L = NULL;
		delete this;
	}

	/**
	 * Lexes the Scintilla document.
	 * @param startPos The position in the document to start lexing at.
	 * @param lengthDoc The number of bytes in the document to lex.
	 * @param initStyle The initial style at position *startPos* in the document.
	 * @param buffer The document interface.
	 */
	void SCI_METHOD Lex(unsigned int startPos, int lengthDoc, int initStyle,
	                    IDocument *buffer) {
		if ((reinit && !Init()) || !L) return;
		lua_pushlightuserdata(L, reinterpret_cast<void *>(&props));
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_props");
		lua_pushlightuserdata(L, reinterpret_cast<void *>(buffer));
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_buffer");
		LexAccessor styler(buffer);

		// Ensure the lexer has a grammar.
		// This could be done in lexer.lex(), but for large files, passing string
		// arguments from C to Lua is expensive.
		lua_getglobal(L, "_LEXER"), lua_getfield(L, -1, "_GRAMMAR");
		int has_grammar = !lua_isnil(L, -1);
		lua_pop(L, 2); // lexer, lexer._GRAMMAR
		if (!has_grammar) return;

		// Start from the beginning of the current style so LPeg matches it.
		// For multilang lexers, start at whitespace since embedded languages have
		// [lang]_whitespace styles. This is so LPeg can start matching child
		// languages instead of parent ones if necessary.
		if (startPos > 0) {
			int i = startPos;
			while (i > 0 && styler.StyleAt(i - 1) == initStyle) i--;
			if (multilang) while (i > 0 && !ws[styler.StyleAt(i)]) i--;
			lengthDoc += startPos - i, startPos = i;
		}

		unsigned int startSeg = startPos, endSeg = startPos + lengthDoc;
		int style = 0;
		lua_getglobal(L, "lexer"), lua_getfield(L, -1, "lex");
		if (lua_isfunction(L, -1)) {
			lua_pushlstring(L, buffer->BufferPointer() + startPos, lengthDoc);
			lua_pushinteger(L, styler.StyleAt(startPos));
			if (lua_pcall(L, 2, 1, 0) != LUA_OK) l_error(L);
			// Style the text from the token table returned.
			if (lua_istable(L, -1)) {
				int len = lua_rawlen(L, -1);
				if (len > 0) {
					styler.StartAt(startPos, static_cast<char>(STYLE_MAX));
					styler.StartSegment(startPos);
					lua_getglobal(L, "_LEXER");
					lua_pushstring(L, "_TOKENS"), lua_rawget(L, -2);
					lua_remove(L, -2); // _LEXER
					// Loop through token-position pairs.
					for (int i = 1; i < len; i += 2) {
						style = STYLE_DEFAULT;
						lua_rawgeti(L, -2, i), lua_rawget(L, -2); // _LEXER._TOKENS[token]
						if (!lua_isnil(L, -1)) style = lua_tointeger(L, -1);
						lua_pop(L, 1); // _LEXER._TOKENS[token]
						lua_rawgeti(L, -2, i + 1); // pos
						unsigned int position = lua_tointeger(L, -1) - 1;
						lua_pop(L, 1); // pos
						if (style >= 0 && style <= STYLE_MAX)
							styler.ColourTo(startSeg + position - 1, style);
						else
							l_error(L, "Bad style number");
						if (position > endSeg) break;
					}
					lua_pop(L, 2); // _LEXER._TOKENS and token table returned
					styler.ColourTo(endSeg - 1, style);
					styler.Flush();
				}
			} else l_error(L, "Table of tokens expected from 'lexer.lex'");
		} else l_error(L, "'lexer.lex' function not found");
		lua_pop(L, 1); // lexer
	}

	/**
	 * Folds the Scintilla document.
	 * @param startPos The position in the document to start folding at.
	 * @param lengthDoc The number of bytes in the document to fold.
	 * @param initStyle The initial style at position *startPos* in the document.
	 * @param buffer The document interface.
	 */
	void SCI_METHOD Fold(unsigned int startPos, int lengthDoc, int initStyle,
	                     IDocument *buffer) {
		if ((reinit && !Init()) || !L) return;
		lua_pushlightuserdata(L, reinterpret_cast<void *>(&props));
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_props");
		lua_pushlightuserdata(L, reinterpret_cast<void *>(buffer));
		lua_setfield(L, LUA_REGISTRYINDEX, "sci_buffer");
		LexAccessor styler(buffer);

		lua_getglobal(L, "lexer"), lua_getfield(L, -1, "fold");
		if (lua_isfunction(L, -1)) {
			int currentLine = styler.GetLine(startPos);
			lua_pushlstring(L, buffer->BufferPointer() + startPos, lengthDoc);
			lua_pushnumber(L, startPos);
			lua_pushnumber(L, currentLine);
			lua_pushnumber(L, styler.LevelAt(currentLine) & SC_FOLDLEVELNUMBERMASK);
			if (lua_pcall(L, 4, 1, 0) != LUA_OK) l_error(L);
			// Fold the text from the fold table returned.
			if (lua_istable(L, -1)) {
				lua_pushnil(L);
				int line = 0, level = 0, maxline = 0, maxlevel = 0;
				while (lua_next(L, -2)) { // [line_num] = fold_level
					line = lua_tointeger(L, -2), level = lua_tointeger(L, -1);
					styler.SetLevel(line, level);
					if (line > maxline) maxline = line, maxlevel = level;
					lua_pop(L, 1); // level
				}
				lua_pop(L, 1); // fold table returned
				// Mask off the level number, leaving only the previous flags.
				int flagsNext = styler.LevelAt(maxline + 1) & ~SC_FOLDLEVELNUMBERMASK;
				styler.SetLevel(maxline + 1, maxlevel | flagsNext);
			} else l_error(L, "Table of folds expected from 'lexer.fold'");
		} else l_error(L, "'lexer.fold' function not found");
		lua_pop(L, 1); // lexer
	}

	/** Returning the version of the lexer is not implemented. */
	int SCI_METHOD Version() const { return 0; }
	/** Returning property names is not implemented. */
	const char * SCI_METHOD PropertyNames() { return ""; }
	/** Returning property types is not implemented. */
	int SCI_METHOD PropertyType(const char *name) { return 0; }
	/** Returning property descriptions is not implemented. */
	const char * SCI_METHOD DescribeProperty(const char *name) { return ""; }
	/**
	 * Sets the *key* lexer property to *value*.
	 * If *key* starts with "style.", also set the style for the token.
	 * @param key The string keyword.
	 * @param val The string value.
	 */
	int SCI_METHOD PropertySet(const char *key, const char *value) {
		props.Set(key, value);
		if (reinit) Init();
#ifdef NO_SCITE
		else if (L && SS && sci && strncmp(key, "style.", 6) == 0) {
			lua_getglobal(L, "_LEXER");
			if (lua_istable(L, -1)) {
				lua_getfield(L, -1, "_TOKENS");
				if (lua_istable(L, -1)) {
					lua_pushstring(L, key + 6), lua_rawget(L, -2);
					lua_pushstring(L, key), lL_getexpanded(L, -1), lua_replace(L, -2);
					if (lua_isnumber(L, -2))
						SetStyle(lua_tointeger(L, -2), lua_tostring(L, -1));
					lua_pop(L, 2); // style and style number
				}
				lua_pop(L, 1); // _LEXER._TOKENS
			}
			lua_pop(L, 1); // _LEXER
		}
#endif
		return -1; // no need to re-lex
	}
	/** Returning keyword list descriptions is not implemented. */
	const char * SCI_METHOD DescribeWordListSets() { return ""; }
	/** Setting keyword lists is not applicable. */
	int SCI_METHOD WordListSet(int n, const char *wl) { return -1; }

	/**
	 * Allows for direct communication between the application and the lexer.
	 * The application uses this to set `SS`, `sci`, and lexer properties, and to
	 * retrieve style names.
	 * @param code The communication code.
	 * @param arg The argument.
	 * @return void *data
	 */
	void * SCI_METHOD PrivateCall(int code, void *arg) {
		sptr_t lParam = reinterpret_cast<sptr_t>(arg);
		const char *val = NULL;
		switch(code) {
		case SCI_GETDIRECTFUNCTION:
			SS = reinterpret_cast<SciFnDirect>(lParam);
			return NULL;
		case SCI_SETDOCPOINTER:
			sci = lParam;
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
				lua_getfield(L, LUA_REGISTRYINDEX, "sci_lexer_name");
				if (SS && sci && multilang) {
					int pos = SS(sci, SCI_GETCURRENTPOS, 0, 0);
					while (pos >= 0 && !ws[SS(sci, SCI_GETSTYLEAT, pos, 0)]) pos--;
					const char *name = NULL, *p = NULL;
					if (pos >= 0) {
						name = GetStyleName(SS(sci, SCI_GETSTYLEAT, pos, 0));
						if (name) p = strstr(name, "_whitespace");
					}
					if (!name) name = lua_tostring(L, -1); // "lexer:lexer" fallback
					if (!p) p = name + strlen(name); // "lexer:lexer" fallback
					lua_pushstring(L, "/");
					lua_pushlstring(L, name, p - name);
					lua_concat(L, 3);
				}
				val = lua_tostring(L, -1);
				lua_pop(L, 1); // lexer_name or lexer language string
			}
			return StringResult(lParam, val);
		default: // style-related
			if (code >= -STYLE_MAX && code < 0) { // retrieve SciTE style strings
#ifndef NO_SCITE
				char prop_name[32];
				sprintf(prop_name, "style.lpeg.%0d", code + STYLE_MAX);
				return StringResult(lParam, props.Get(prop_name));
#else
				return NULL;
#endif
			} else if (code <= STYLE_MAX) { // retrieve style names
				val = GetStyleName(code);
				return StringResult(lParam, val ? val : "Not Available");
			} else return NULL;
		}
	}

	/** Constructs a new instance of the lexer. */
	static ILexer *LexerFactoryLPeg() { return new LexerLPeg(); }
};

#ifdef LPEG_LEXER_EXTERNAL
#ifdef _WIN32
#define EXT_LEXER_DECL __declspec( dllexport ) __stdcall
#else
#define EXT_LEXER_DECL
#endif // _WIN32
extern "C" {
/** Returns 1, the number of lexers defined in this file. */
int EXT_LEXER_DECL GetLexerCount() { return 1; }
/**
 * Copies the name of the lexer into buffer *name* of size *len*.
 * @param index 0, the lexer number to get the name of.
 * @param name The buffer to copy the name of the lexer into.
 * @param len The size of *name*.
 */
void EXT_LEXER_DECL GetLexerName(unsigned int index, char *name, int len) {
	*name = '\0';
	if ((index == 0) && (len > strlen("lpeg"))) strcpy(name, "lpeg");
}
/**
 * Returns the function that creates a new instance of the lexer.
 * @param index 0, the number of the lexer to create a new instance of.
 * @return factory function
 */
LexerFactoryFunction EXT_LEXER_DECL GetLexerFactory(unsigned int index) {
	return (index == 0) ? LexerLPeg::LexerFactoryLPeg : 0;
}
}
/*
Forward the following properties from SciTE.
GetProperty "lexer.lpeg.home"
GetProperty "lexer.lpeg.color.theme"
GetProperty "fold.by.indentation"
GetProperty "fold.line.comments"
*/
#else
LexerModule lmLPeg(SCLEX_AUTOMATIC - 1, LexerLPeg::LexerFactoryLPeg, "lpeg");
#endif // LPEG_LEXER_EXTERNAL

#endif // LPEG_LEXER || LPEG_LEXER_EXTERNAL
