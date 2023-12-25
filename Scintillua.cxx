// Copyright 2006-2024 Mitchell. See LICENSE.

#include <cassert>
#include <cstring>

#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <memory>

#include "ILexer.h"

#include "Scintilla.h"

#include "PropSetSimple.h"
#include "LexAccessor.h"
#include "OptionSet.h"
#include "DefaultLexer.h"

#include "Scintillua.h"

extern "C" {
#include "lua.h"
#include "lualib.h" // LUALIB_API
#include "lauxlib.h"
LUALIB_API int luaopen_lpeg(lua_State *L);
}

namespace {

class Scintillua : public Lexilla::DefaultLexer {
  std::string name;
  std::unique_ptr<lua_State, decltype(&lua_close)> L; // cleared when lexer language changes
  Lexilla::PropSetSimple props;
  bool multilang = false;
  // The list of style numbers considered to be whitespace styles.
  // This is used in multi-language lexers when backtracking to whitespace to determine which
  // lexer grammar to use.
  bool ws[STYLE_MAX];
  std::string privateCallResult; // used by PrivateCall for persistence
  std::string wordListsDescription; // used by DescribeWordListSets() for persistence
  std::string styleName; // used by NameOfStyle() for persistence

  // Property documentation. Actual property data is set and handled in Lua.
  struct Placeholder {
    std::string s;
    bool b;
  };
  Placeholder placeholder;
  struct PropertyDoc : public Lexilla::OptionSet<Placeholder> {
    PropertyDoc();
  };
  PropertyDoc properties;

  // Logs the given error message or a Lua error message, prints it (if requested), and clears
  // the stack. Error messages are logged to the LexerErrorKey property.
  void LogError(const char *str = nullptr, bool print = true);

public:
  static constexpr const char *LexerErrorKey = "lexer.scintillua.error";

  Scintillua(const std::string &lexersDir, const char *name);
  virtual ~Scintillua() override = default;

  void SCI_METHOD Release() override;

  const char *SCI_METHOD PropertyNames() override;
  int SCI_METHOD PropertyType(const char *name_) override;
  const char *SCI_METHOD DescribeProperty(const char *name_) override;

  Sci_Position SCI_METHOD PropertySet(const char *key, const char *value) override;

  // Note: the returned value persists only until the next call.
  const char *SCI_METHOD DescribeWordListSets() override;
  Sci_Position SCI_METHOD WordListSet(int n, const char *wl) override;

  void SCI_METHOD Lex(Sci_PositionU startPos, Sci_Position lengthDoc, int initStyle,
    Scintilla::IDocument *buffer) override;

  void SCI_METHOD Fold(
    Sci_PositionU startPos, Sci_Position lengthDoc, int, Scintilla::IDocument *buffer) override;

  void *SCI_METHOD PrivateCall(int operation, void *pointer) override;

  // Note: includes predefined styles.
  int SCI_METHOD NamedStyles() override;
  // Note: the returned value persists only until the next call.
  const char *SCI_METHOD NameOfStyle(int style) override;

  const char *SCI_METHOD PropertyGet(const char *key) override;

  const char *SCI_METHOD GetName() override;
};

// Ensures that the Lua stack contains the same number of stack values at the beginning and
// end of this object's lifetime (thus the stack does not grow or shrink over time).
class DeferLuaStackCheck {
public:
  DeferLuaStackCheck(lua_State *L) : L(L), top(lua_gettop(L)) {}
  ~DeferLuaStackCheck() { assert(lua_gettop(L) == top); }

private:
  lua_State *L;
  int top;
};

Scintillua::PropertyDoc::PropertyDoc() {
  DefineProperty(LexerErrorKey, &Placeholder::s, "Error message from most recent operation.");
  DefineProperty("fold", &Placeholder::b, "Enable folding.");
  DefineProperty("fold.scintillua.by.indentation", &Placeholder::b,
    "Fold based on indentation level if a lexer does not have its own folder. Note some lexers "
    "automatically enable this.");
  DefineProperty("fold.scintillua.on.zero.sum.lines", &Placeholder::b,
    "Mark as a fold point lines that contain both an ending and starting fold point (e.g. '} "
    "else {').");
  DefineProperty(
    "fold.scintillua.compact", &Placeholder::b, "Include in a fold any subsequent blank lines.");
  DefineProperty("lexer.scintillua.filename", &Placeholder::s,
    "The filename for detecting a lexer via PrivateCall.");
  DefineProperty("lexer.scintillua.line", &Placeholder::s,
    "The content line for detecting a lexer via PrivateCall.");
}

void Scintillua::LogError(const char *str, bool print) {
  const char *value = str ? str : lua_tostring(L.get(), -1);
  PropertySet(LexerErrorKey, value);
  if (print) fprintf(stderr, "Lua Error: %s.\n", value);
  lua_settop(L.get(), 0);
}

// Lua xpcall error handler that appends traceback.
int lua_error_handler(lua_State *L) { return (luaL_traceback(L, L, lua_tostring(L, -1), 1), 1); }

// lexer.field[key] metamethod.
int lexer_field_index(lua_State *L) {
  const std::string_view field{lua_tostring(L, lua_upvalueindex(1))};
  lua_getfield(L, LUA_REGISTRYINDEX, "scintillua"); // REGISTRY.scintillua
  const auto scintillua = reinterpret_cast<Scintillua *>(lua_touserdata(L, -1));
  lua_getfield(L, LUA_REGISTRYINDEX, "buffer"); // assume it's available too
  const auto buffer = static_cast<Scintilla::IDocument *>(lua_touserdata(L, -1));
  if (field == "fold_level") {
    if (!buffer) luaL_error(L, "must be lexing or folding");
    lua_pushinteger(L, buffer->GetLevel(luaL_checkinteger(L, 2) - 1)); // incoming line is 1-based
  } else if (field == "indent_amount") {
    if (!buffer) luaL_error(L, "must be lexing or folding");
    lua_pushinteger(L, buffer->GetLineIndentation(luaL_checkinteger(L, 2) - 1)); // 1-based line
  } else if (field == "property" || field == "property_int") {
    lua_pushstring(L, scintillua->PropertyGet(luaL_checkstring(L, 2)));
    if (field == "property_int") lua_pushinteger(L, lua_tointeger(L, -1));
  } else if (field == "style_at") {
    if (!buffer) luaL_error(L, "must be lexing or folding");
    const Sci_PositionU startPos =
      (lua_getfield(L, LUA_REGISTRYINDEX, "startPos"), lua_tointeger(L, -1)); // REGISTRY.startPos
    const int style = buffer->StyleAt(startPos + luaL_checkinteger(L, 2) - 1); // 1-based position
    lua_pushstring(L, scintillua->NameOfStyle(style));
  } else if (field == "line_state") {
    if (!buffer) luaL_error(L, "must be lexing or folding");
    lua_pushinteger(L, buffer->GetLineState(luaL_checkinteger(L, 2) - 1)); // 1-based line
  }
  return 1;
}

// lexer.field[key] = value metamethod.
int lexer_field_newindex(lua_State *L) {
  const std::string_view field{lua_tostring(L, lua_upvalueindex(1))};
  luaL_argcheck(L,
    field != "fold_level" && field != "indent_amount" && field != "property_int" &&
      field != "style_at" && field != "line_from_position",
    3, "read-only field");
  lua_getfield(L, LUA_REGISTRYINDEX, "scintillua"); // REGISTRY.scintillua
  const auto lexer = reinterpret_cast<Scintillua *>(lua_touserdata(L, -1));
  if (field == "property") {
    if (strncmp(lua_tostring(L, 2), "scintillua.comment.", strlen("scintillua.comment.")) != 0) {
      static constexpr const char *validKeys[] = {
        "scintillua.comment", "scintillua.angle.braces", "scintillua.word.chars"};
      luaL_checkoption(L, 2, nullptr, validKeys);
    }
    lexer->PropertySet(luaL_checkstring(L, 2), luaL_checkstring(L, 3));
  } else if (field == "line_state") {
    if (lua_getfield(L, LUA_REGISTRYINDEX, "buffer") != LUA_TLIGHTUSERDATA) // REGISTRY.buffer
      luaL_error(L, "must be lexing or folding");
    const auto buffer = static_cast<Scintilla::IDocument *>(lua_touserdata(L, -1));
    const Sci_Position line = luaL_checkinteger(L, 2) - 1; // incoming line is 1-based
    buffer->SetLineState(line, luaL_checkinteger(L, 3));
  }
  return 0;
}

// lexer.line_from_position()
// Note: position argument from Lua is 1-based.
int line_from_position(lua_State *L) {
  if (lua_getfield(L, LUA_REGISTRYINDEX, "buffer") != LUA_TLIGHTUSERDATA) // REGISTRY.buffer
    luaL_error(L, "must be lexing or folding");
  const auto buffer = static_cast<Scintilla::IDocument *>(lua_touserdata(L, -1));
  const Sci_PositionU startPos =
    (lua_getfield(L, LUA_REGISTRYINDEX, "startPos"), lua_tointeger(L, -1)); // REGISTRY.startPos
  lua_pushinteger(L, buffer->LineFromPosition(startPos + luaL_checkinteger(L, 1) - 1) + 1);
  return 1;
}

// lexer[key] metamethod.
int lexer_index(lua_State *L) {
  const std::string_view key{lua_tostring(L, 2)};
  if (key == "fold_level" || key == "indent_amount" || key == "property" || key == "property_int" ||
    key == "style_at" || key == "line_state") {
    lua_newtable(L);
    lua_createtable(L, 0, 2);
    lua_pushvalue(L, 2), lua_pushcclosure(L, lexer_field_index, 1), lua_setfield(L, -2, "__index");
    lua_pushvalue(L, 2), lua_pushcclosure(L, lexer_field_newindex, 1),
      lua_setfield(L, -2, "__newindex");
    lua_setmetatable(L, -2); // return setmetatable({}, {__index = f, __newindex = f})
  } else if (key == "line_from_position")
    lua_pushcfunction(L, line_from_position);
  else
    lua_rawget(L, 1); // lexer[key]
  return 1;
}

// lexer[key] = value metamethod.
int lexer_newindex(lua_State *L) {
  const std::string_view key{lua_tostring(L, 2)};
  luaL_argcheck(L,
    key != "fold_level" && key != "indent_amount" && key != "property" && key != "property_int" &&
      key != "style_at" && key != "line_state" && key != "line_from_position",
    3, "read-only field");
  return (lua_rawset(L, 1), 0); // lexer[key] = value
}

Scintillua::Scintillua(const std::string &lexersDir, const char *name)
    : DefaultLexer("scintillua", -1), name(name), L{luaL_newstate(), lua_close} {
  if (lexersDir.empty()) {
    LogError("scintillua.lexers library property not set");
    return;
  }
  PropertySet("scintillua.lexers", lexersDir.c_str());
  DeferLuaStackCheck checker{L.get()};

  luaL_requiref(L.get(), "_G", luaopen_base, 1), lua_pop(L.get(), 1);
  luaL_requiref(L.get(), LUA_TABLIBNAME, luaopen_table, 1), lua_pop(L.get(), 1);
  luaL_requiref(L.get(), LUA_STRLIBNAME, luaopen_string, 1), lua_pop(L.get(), 1);
  luaL_requiref(L.get(), "lpeg", luaopen_lpeg, 1), lua_pop(L.get(), 1);
  luaL_requiref(L.get(), LUA_MATHLIBNAME, luaopen_math, 1), lua_pop(L.get(), 1);
  luaL_requiref(L.get(), LUA_UTF8LIBNAME, luaopen_utf8, 1), lua_pop(L.get(), 1);
  lua_pushlightuserdata(L.get(), this),
    lua_setfield(L.get(), LUA_REGISTRYINDEX, "scintillua"); // REGISTRY.scintillua = this

  // Load the lexer module.
  size_t start, end = 0;
  while ((start = lexersDir.find_first_not_of(';', end)) != std::string::npos) {
    end = lexersDir.find(';', start);
    std::string dir{lexersDir, start, end - start};
    dir.append("/lexer.lua");
    switch (luaL_loadfile(L.get(), dir.c_str())) { // loadfile('path/to/lexer.lua')
    case LUA_ERRFILE:
      lua_pop(L.get(), 1); // error message
      continue; // try next directory
    case LUA_OK:
      lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
      if (lua_pcall(L.get(), 0, 1, -2) != LUA_OK) { // lexer = xpcall(loadfile('lexer.lua'), msgh)
        LogError();
        return;
      }
      lua_remove(L.get(), -2); // lua_error_handler
      break;
    default: LogError(); return;
    }
  }
  if (!lua_gettop(L.get())) {
    LogError("could not find lexer.lua");
    return;
  }
  if (!lua_istable(L.get(), -1)) {
    LogError("expected module return from lexer.lua");
    return;
  }

  lua_pushinteger(L.get(), SC_FOLDLEVELBASE), lua_setfield(L.get(), -2, "FOLD_BASE");
  lua_pushinteger(L.get(), SC_FOLDLEVELWHITEFLAG), lua_setfield(L.get(), -2, "FOLD_BLANK");
  lua_pushinteger(L.get(), SC_FOLDLEVELHEADERFLAG), lua_setfield(L.get(), -2, "FOLD_HEADER");
  lua_createtable(L.get(), 0, 2);
  lua_pushcfunction(L.get(), lexer_index), lua_setfield(L.get(), -2, "__index");
  lua_pushcfunction(L.get(), lexer_newindex), lua_setfield(L.get(), -2, "__newindex");
  lua_setmetatable(L.get(), -2); // setmetatable(lexer, {__index = f, __newindex = f})

  lua_getfield(L.get(), LUA_REGISTRYINDEX, "_LOADED");
  lua_pushvalue(L.get(), -2), lua_setfield(L.get(), -2, "lexer"); // _LOADED['lexer'] = lexer
  lua_pop(L.get(), 1); // _LOADED

  // Call lexer.load(name).
  if (lua_getfield(L.get(), -1, "load") != LUA_TFUNCTION) {
    LogError("cannot find lexer.load()");
    return;
  }
  lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
  lua_pushstring(L.get(), name);
  if (lua_pcall(L.get(), 1, 1, -3) != LUA_OK) { // lex = xpcall(lexer.load, msgh, name)
    const bool print = !strstr(lua_tostring(L.get(), -1), "no file");
    LogError(nullptr, print);
    return;
  }
  lua_remove(L.get(), -2); // lua_error_handler
  lua_pushvalue(L.get(), -1), lua_setfield(L.get(), LUA_REGISTRYINDEX, "lex"); // REGISTRY.lex = lex

  if (lua_getfield(L.get(), -1, "_CHILDREN") == LUA_TTABLE) { // lex._CHILDREN
    multilang = true;
    for (int i = 0; i < STYLE_MAX; i++) ws[i] = strstr(NameOfStyle(i), "whitespace") != nullptr;
  }
  lua_pop(L.get(), 1); // lex._CHILDREN

  lua_pop(L.get(), 2); // lex, lexer
  PropertySet(LexerErrorKey, "");
}

void Scintillua::Release() { delete this; }

const char *Scintillua::PropertyNames() { return properties.PropertyNames(); }
int Scintillua::PropertyType(const char *name_) { return properties.PropertyType(name_); }
const char *Scintillua::DescribeProperty(const char *name_) {
  return properties.DescribeProperty(name_);
}

Sci_Position Scintillua::PropertySet(const char *key, const char *value) {
  const bool reLex = properties.PropertySet(&placeholder, key, value);
  props.Set(key, value);
  return reLex ? 0 : -1;
}

const char *SCI_METHOD Scintillua::DescribeWordListSets() {
  DeferLuaStackCheck checker{L.get()};
  wordListsDescription = "";
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex
  if (lua_getfield(L.get(), -1, "_WORDLISTS") == LUA_TTABLE) { // lex._WORDLISTS
    std::vector<std::string> names(lua_rawlen(L.get(), -1));
    for (lua_pushnil(L.get()); lua_next(L.get(), -2); lua_pop(L.get(), 1))
      if (lua_type(L.get(), -2) == LUA_TSTRING && lua_isnumber(L.get(), -1)) // {name = i}
        names[lua_tointeger(L.get(), -1) - 1] = lua_tostring(L.get(), -2); // indices are 1-based
    for (size_t i = 0; i < names.size(); i++)
      wordListsDescription.append(names[i]), wordListsDescription.append("\n");
  }
  lua_pop(L.get(), 2); // lex._WORDLISTS, lex
  return wordListsDescription.c_str();
}

Sci_Position SCI_METHOD Scintillua::WordListSet(int n, const char *wl) {
  DeferLuaStackCheck checker{L.get()};
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex
  if (lua_getfield(L.get(), -1, "set_word_list") != LUA_TFUNCTION) // lex.set_word_list
    return (LogError("cannot find lexer.set_word_list()"), 0);
  lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
  lua_pushvalue(L.get(), -3);
  lua_pushinteger(L.get(), n + 1); // convert to 1-based
  lua_pushstring(L.get(), wl);
  if (lua_pcall(L.get(), 3, 0, -5) != LUA_OK) // xpcall(lex.set_word_list, msgh, lex, n, wl)
    return (LogError(), 0);
  lua_pop(L.get(), 2); // lua_error_handler, lex
  return 1; // re-lex
}

// RAII for Lua registry fields.
class LuaRegistryField {
  lua_State *L;
  const char *key;

public:
  LuaRegistryField(lua_State *L, const char *key, void *value) : L(L), key{key} {
    lua_pushlightuserdata(L, value), lua_setfield(L, LUA_REGISTRYINDEX, key);
  }
  LuaRegistryField(lua_State *L, const char *key, Sci_PositionU value) : L(L), key{key} {
    lua_pushinteger(L, value), lua_setfield(L, LUA_REGISTRYINDEX, key);
  }
  ~LuaRegistryField() { lua_pushnil(L), lua_setfield(L, LUA_REGISTRYINDEX, key); }
};

void Scintillua::Lex(
  Sci_PositionU startPos, Sci_Position lengthDoc, int initStyle, Scintilla::IDocument *buffer) {
  Lexilla::LexAccessor styler(buffer);
  DeferLuaStackCheck checker{L.get()};
  LuaRegistryField regBuf{L.get(), "buffer", buffer}; // REGISTRY.buffer = buffer
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex

  // Start from the beginning of the current style so the lexer can match the tag.
  // For multilang lexers, start at whitespace since embedded languages have whitespace.[lang]
  // styles. This is so the lexer can start matching child languages instead of parent ones
  // if necessary.
  if (startPos > 0) {
    Sci_PositionU i = startPos;
    while (i > 0 && styler.StyleAt(i - 1) == initStyle) i--;
    if (multilang)
      while (i > 0 && !ws[static_cast<size_t>(styler.StyleAt(i))]) i--;
    lengthDoc += startPos - i, startPos = i;
  }
  styler.StartAt(startPos);
  styler.StartSegment(startPos);
  LuaRegistryField regStartPos{L.get(), "startPos", startPos}; // REGISTRY.startPos = startPos

  // Call lexer.lex(lex, text, init_style).
  if (lua_getfield(L.get(), -1, "lex") != LUA_TFUNCTION) {
    styler.ColourTo(startPos + lengthDoc - 1, initStyle), styler.Flush();
    return LogError("cannot find lexer.lex()");
  }
  lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
  lua_pushvalue(L.get(), -3);
  lua_pushlstring(L.get(), buffer->BufferPointer() + startPos, lengthDoc);
  lua_pushinteger(L.get(), styler.StyleAt(startPos) + 1);
  if (lua_pcall(L.get(), 3, 1, -5) != LUA_OK) { // t = xpcall(lexer.lex, msgh, lex, text, initStyle)
    styler.ColourTo(startPos + lengthDoc - 1, initStyle), styler.Flush();
    return LogError();
  }
  lua_remove(L.get(), -2); // lua_error_handler
  if (!lua_istable(L.get(), -1)) {
    styler.ColourTo(startPos + lengthDoc - 1, initStyle), styler.Flush();
    return LogError("table of tags expected from lexer.lex()");
  }

  // Style the text from the returned table of tags.
  const int len = lua_rawlen(L.get(), -1);
  if (len > 0) {
    int style = STYLE_DEFAULT;
    lua_getfield(L.get(), -2, "_TAGS"); // lex._TAGS
    for (int i = 1; i < len; i += 2) { // for i = 1, #t, 2 do ... end
      style = STYLE_DEFAULT;
      lua_rawgeti(L.get(), -2, i); // tag = t[i]
      if (lua_rawget(L.get(), -2)) // lex._TAGS[tag]
        style = lua_tointeger(L.get(), -1) - 1; // returned styles are 1-based
      lua_pop(L.get(), 1); // lex._TAGS[tag]
      lua_rawgeti(L.get(), -2, i + 1); // pos = t[i + 1]
      const Sci_PositionU position = lua_tointeger(L.get(), -1) - 1; // returned pos is 1-based
      lua_pop(L.get(), 1); // pos
      if (style < 0 || style >= STYLE_MAX) {
        styler.ColourTo(startPos + lengthDoc - 1, initStyle), styler.Flush();
        lua_pushfstring(L.get(), "invalid style number: %d", style);
        return LogError();
      }
      styler.ColourTo(startPos + position - 1, style);
      if (position > startPos + lengthDoc) break;
    }
    lua_pop(L.get(), 1); // lex._TAGS
    styler.ColourTo(startPos + lengthDoc - 1, style);
    styler.Flush();
  }
  lua_pop(L.get(), 1); // tag table

  lua_pop(L.get(), 1); // lex
}

void Scintillua::Fold(
  Sci_PositionU startPos, Sci_Position lengthDoc, int, Scintilla::IDocument *buffer) {
  Lexilla::LexAccessor styler(buffer);
  DeferLuaStackCheck checker{L.get()};
  LuaRegistryField regBuf{L.get(), "buffer", buffer}; // REGISTRY.buffer = buffer
  LuaRegistryField regStartPos{L.get(), "startPos", startPos}; // REGISTRY.startPos = startPos

  // Call lexer.fold(lex, text, start_pos, start_line, start_level).
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex
  if (lua_getfield(L.get(), -1, "fold") != LUA_TFUNCTION)
    return LogError("cannot find lexer.fold()");
  lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
  lua_pushvalue(L.get(), -3);
  const Sci_Position currentLine = styler.GetLine(startPos);
  lua_pushlstring(L.get(), buffer->BufferPointer() + startPos, lengthDoc);
  lua_pushinteger(L.get(), currentLine + 1);
  lua_pushinteger(L.get(), styler.LevelAt(currentLine) & SC_FOLDLEVELNUMBERMASK);
  if (lua_pcall(L.get(), 4, 1, -6) != LUA_OK) // t = xpcall(lexer.fold, msgh, lex, txt, ln, lvl)
    return LogError();
  lua_remove(L.get(), -2); // lua_error_handler
  lua_remove(L.get(), -2); // lex
  if (!lua_istable(L.get(), -1)) return LogError("table of folds expected from lexer.fold()");

  // Fold the text from the returned table of fold levels.
  for (lua_pushnil(L.get()); lua_next(L.get(), -2); lua_pop(L.get(), 1)) // {line = level}
    styler.SetLevel(lua_tointeger(L.get(), -2) - 1, lua_tointeger(L.get(), -1)); // line is 1-based
  lua_pop(L.get(), 1); // fold table
}

void *SCI_METHOD Scintillua::PrivateCall(int operation, void *pointer) {
  if (operation != SCLUA_DETECT) return (LogError("invalid private call operation"), nullptr);
  if (pointer)
    return (memcpy(pointer, privateCallResult.c_str(), privateCallResult.size()), nullptr);
  DeferLuaStackCheck checker{L.get()};
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "_LOADED"), lua_getfield(L.get(), -1, "lexer"),
    lua_replace(L.get(), -2); // _LOADED['lexer']
  if (!lua_istable(L.get(), -1)) return (LogError("cannot find lexer module"), nullptr);
  if (lua_getfield(L.get(), -1, "detect") != LUA_TFUNCTION)
    return (LogError("cannot find lexer.detect()"), nullptr);
  lua_pushcfunction(L.get(), lua_error_handler), lua_insert(L.get(), -2);
  if (lua_pcall(L.get(), 0, 1, -2) != LUA_OK) // lexer_name = xpcall(lexer.detect)
    return (LogError(), nullptr);
  lua_remove(L.get(), -2); // lua_error_handler
  const char *lexer_name = lua_tostring(L.get(), -1);
  privateCallResult = lexer_name ? lexer_name : "";
  lua_pop(L.get(), 2); // lexer_name, _LOADED['lexer']
  return reinterpret_cast<void *>(static_cast<uintptr_t>(privateCallResult.size()));
}

// Note: includes the names of predefined styles.
int Scintillua::NamedStyles() {
  DeferLuaStackCheck checker{L.get()};
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex
  lua_getfield(L.get(), -1, "_TAGS"); // lex._TAGS
  const int num = lua_rawlen(L.get(), -1); // #lex._TAGS
  lua_pop(L.get(), 2); // lex._TAGS, lex
  return num;
}

const char *Scintillua::NameOfStyle(int style) {
  styleName = "Unknown";
  DeferLuaStackCheck checker{L.get()};
  lua_getfield(L.get(), LUA_REGISTRYINDEX, "lex"); // lex = REGISTRY.lex
  lua_getfield(L.get(), -1, "_TAGS"); // lex._TAGS
  if (lua_rawgeti(L.get(), -1, style + 1)) // style in _TAGS is 1-based
    styleName = lua_tostring(L.get(), -1); // name = lex._TAGS[style]
  lua_pop(L.get(), 3); // name, lex._TAGS, lex
  return styleName.c_str();
}

const char *Scintillua::PropertyGet(const char *key) { return props.Get(key); }

const char *Scintillua::GetName() { return name.c_str(); }

#if _WIN32
#if !NO_DLL
#define EXPORT_FUNCTION __declspec(dllexport)
#define CALLING_CONVENTION __stdcall
#else
#define EXPORT_FUNCTION extern
#define CALLING_CONVENTION
#endif
#else
#define EXPORT_FUNCTION __attribute__((visibility("default")))
#define CALLING_CONVENTION
#endif // _WIN32

extern "C" {

EXPORT_FUNCTION int CALLING_CONVENTION GetLexerCount() { return 1; }

EXPORT_FUNCTION void CALLING_CONVENTION GetLexerName(unsigned int index, char *name, int len) {
  *name = '\0';
  if ((index == 0) && (len > static_cast<int>(strlen("scintillua")))) strcpy(name, "scintillua");
}

EXPORT_FUNCTION const char *CALLING_CONVENTION GetLibraryPropertyNames() {
  return "scintillua.lexers\n";
}

std::string lexersDir;

EXPORT_FUNCTION void CALLING_CONVENTION SetLibraryProperty(const char *key, const char *value) {
  if (std::string_view{key} == "scintillua.lexers") lexersDir = value;
}

EXPORT_FUNCTION const char *CALLING_CONVENTION GetNameSpace() { return "scintillua"; }

std::string errorMessage;

EXPORT_FUNCTION Scintilla::ILexer5 *CALLING_CONVENTION CreateLexer(const char *name) {
  auto lexer = new Scintillua(lexersDir, name);
  errorMessage = lexer->PropertyGet(Scintillua::LexerErrorKey);
  if (errorMessage.length() > 0) {
    lexer->Release();
    return nullptr;
  }
  return lexer;
}

EXPORT_FUNCTION const char *CALLING_CONVENTION GetCreateLexerError() {
  return errorMessage.c_str();
}
}

} // namespace
