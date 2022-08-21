-- Copyright 2017-2022 Mitchell. See LICENSE.
-- Unit tests for Scintillua lexers.

package.path = 'lexers/?.lua;' .. package.path

local lexer = require('lexer')
local word_match = lexer.word_match
lpeg = require('lpeg') -- not local for use by lexers in Lua 5.2+
-- Scintilla normally defines these.
lexer.FOLD_BASE, lexer.FOLD_HEADER, lexer.FOLD_BLANK = 0x400, 0x2000, 0x1000

-- Helper assert functions.

-- Asserts the given lexer contains the default Scintillua tags and Scintilla style names, and
-- that those items are correctly numbered. Scintillua tag numbers start at 1 while Scintilla
-- style numbers start at 33.
-- Note: the tag and style tables used are copied from lexer.lua since they are local to that file.
-- @param lex The lexer to style-check.
function assert_default_tags(lex)
  local default_tags = {
    'nothing', 'whitespace', 'comment', 'string', 'number', 'keyword', 'identifier', 'operator',
    'error', 'preprocessor', 'constant', 'variable', 'function', 'class', 'type', 'label', 'regex',
    'embedded'
  }
  for i = 1, #default_tags do
    local tag = default_tags[i]
    assert(lex._TAGS[tag], string.format("tag '%s' does not exist", tag))
    assert(lex._TAGS[tag] == i, 'default styles out of order')
  end
  local predefined_styles = {
    'default', 'line_number', 'brace_light', 'brace_bad', 'control_char', 'indent_guide',
    'call_tip', 'fold_display_text'
  }
  for i = 1, #predefined_styles do
    local style = predefined_styles[i]
    assert(lex._TAGS[style], string.format("style '%s' does not exist", style))
    assert(lex._TAGS[style] == i + 32, 'predefined styles out of order')
  end
  assert(lex._TAGS['whitespace.' .. lex._name]) -- auto-added by lexer.new()
end

-- Asserts the given lexer contains the given ordered list of rules.
-- @param lex The lexer to rule-check.
-- @param rules The ordered list of rule names the lexer should have.
function assert_rules(lex, rules)
  if rules[1] ~= 'whitespace' then table.insert(rules, 1, 'whitespace') end -- auto-added
  if not lex._lexer then
    for i = 1, lexer.num_user_word_lists do table.insert(rules, i + 1, 'userlist' .. i) end -- auto-added
  end
  local j = 1
  for i = 1, #lex._rules do
    assert(lex._rules[rules[j]], string.format("rule '%s' does not exist", rules[j]))
    assert(lex._rules[i] == rules[j], string.format("'%s' ~= '%s'", lex._rules[i], rules[i] or ''))
    j = j + 1
  end
  if #lex._rules ~= #rules then error(string.format("'%s' rule not found", rules[j])) end
end

-- Asserts the given lexer contains the given set of extra tags in addition to its defaults.
-- @param lex The lexer to style-check.
-- @param tags The list of extra tag names the lexer should have.
function assert_extra_tags(lex, tags)
  for i = 1, #tags do
    assert(lex._TAGS[tags[i]], string.format("'%s' not found", tags[i]))
    assert(lex._extra_tags[tags[i]], string.format("'%s' not found", tags[i]))
  end
end

-- Asserts the given lexer contains the given set of child lexer names.
-- @param lex The lexer to child-check.
-- @param children The list of child lexer names the lexer should have.
function assert_children(lex, children)
  local j = 1
  for i = 1, #lex._CHILDREN do
    assert(lex._CHILDREN[i]._name == children[j],
      string.format("'%s' ~= '%s'", lex._CHILDREN[i]._name, children[j] or ''))
    j = j + 1
  end
  if #lex._CHILDREN ~= #children then error(string.format("child '%s' not found", children[j])) end
end

-- Asserts the given lexer produces the given tags after lexing the given code.
-- @param lex The lexer to use.
-- @param code The string code to lex.
-- @param expected_tags The list of expected tags from the lexer. Each tag is a table that
--   contains the tag's name followed by the substring of code matched. Whitespace tags are
--   ignored for the sake of simplicity. Do not include them.
-- @param initial_style Optional current style. This is used for determining which language to
--   start in in a multiple-language lexer.
-- @usage assert_lex(lua, "print('hi')", {{'function', 'print'}, {'operator', '('},
--   {'string', "'hi'"}, {'operator', ')'}})
function assert_lex(lex, code, expected_tags, initial_style)
  if lex._lexer then lex = lex._lexer end -- note: lexer.load() does this
  local tags = lex:lex(code, initial_style or lex._TAGS['whitespace.' .. lex._name])
  local j = 1
  for i = 1, #tags, 2 do
    if not tags[i]:find('^whitespace') then
      local tag = tags[i]
      local text = code:sub(tags[i - 1] or 0, tags[i + 1] - 1)
      assert(tag == expected_tags[j][1] and text == expected_tags[j][2], string.format(
        "('%s', '%s') ~= ('%s', '%s')", tag, text, expected_tags[j][1], expected_tags[j][2]))
      j = j + 1
    end
  end
  if j - 1 ~= #expected_tags then
    error(string.format("('%s', '%s') not found", expected_tags[j][1], expected_tags[j][2]))
  end
end

-- Asserts the given lexer produces the given fold points after lexing the given code.
-- @param lex The lexer to use.
-- @param code The string code to fold.
-- @param expected_fold_points The list of expected fold points from the lexer. Each fold point
--   is just a line number, starting from 1.
-- @param initial_style Optional current style. This is used for determining which language to
--   start in in a multiple-language lexer.
-- @return fold levels for any further analysis
-- @usage assert_fold_points(lua, "if foo then\n  bar\nend", {1})
function assert_fold_points(lex, code, expected_fold_points, initial_style)
  if lex._lexer then lex = lex._lexer end -- note: lexer.load() does this
  -- Since `M.style_at()` is provided by Scintilla and not available for tests, create it,
  -- using data from `lexer.lex()`.
  local tags = lex:lex(code, initial_style or lex._TAGS['whitespace.' .. lex._name])
  lexer.style_at = setmetatable({}, {
    __index = function(self, pos)
      for i = 2, #tags, 2 do if pos < tags[i] then return tags[i - 1] end end
    end
  })
  if not lexer.property then -- Scintilla normally creates this
    lexer.property, lexer.property_int = {}, setmetatable({}, {
      __index = function(t, k) return tonumber(lexer.property[k]) or 0 end,
      __newindex = function() error('read-only property') end
    })
  end
  lexer.property['fold'] = 1
  local levels = lex:fold(code, 1, 1, lexer.FOLD_BASE)
  local j = 1
  for i = 1, #levels do
    local line_num = expected_fold_points[j]
    if i == line_num then
      assert(levels[i] >= lexer.FOLD_HEADER, string.format("line %i not a fold point", i))
      j = j + 1
    elseif line_num and i == -line_num then
      assert(levels[i] > levels[i + 1] & ~(lexer.FOLD_HEADER | lexer.FOLD_BLANK),
        string.format("line %i is not a fold end point", i))
      j = j + 1
    else
      assert(levels[i] <= lexer.FOLD_HEADER, string.format("line %i is a fold point", i))
    end
  end
  assert(j - 1 == #expected_fold_points, string.format("line %i is not a fold point", j))
  return levels
end

-- Unit tests.

function test_to_eol()
  local code = '#foo\\\nbar\\\nbaz'
  assert(lexer.to_eol('#'):match(code) == 6)
  assert(lexer.to_eol('#', true):match(code) == #code + 1)
end

function test_range()
  assert(lexer.range('"'):match('"foo\\"bar\n"baz') == 12)
  assert(lexer.range('"', true):match('"foo\\"bar\n"baz') == 10)
  assert(lexer.range('"', false, false):match('"foo\\"bar\n"baz') == 7)

  assert(lexer.range('(', ')'):match('(foo\\)bar)baz') == 7)

  assert(lexer.range('/*', '*/'):match('/*/*foo*/bar*/baz') == 10)
  assert(lexer.range('/*', '*/', false, false, true):match('/*/*foo*/bar*/baz') == 15)
end

function test_starts_line()
  assert(lexer.starts_line('#'):match('#foo') == 2)
  assert(lexer.starts_line('#'):match('\n#foo', 2) == 3)
  assert(not lexer.starts_line('#'):match(' #foo', 2))
end

function test_last_char_includes()
  assert(lexer.last_char_includes('=,'):match('/foo/'))
  assert(lexer.last_char_includes('=,'):match('foo=/bar/', 5) == 5)
  assert(lexer.last_char_includes('=,'):match('foo, /bar/', 6) == 6)
  assert(not lexer.last_char_includes('=,'):match('foo/bar', 4))
end

function test_word_match()
  assert(word_match{'foo', 'bar', 'baz'}:match('foo') == 4)
  assert(not word_match{'foo', 'bar', 'baz'}:match('foo_bar'))
  assert(word_match({'foo!', 'bar?', 'baz.'}, true):match('FOO!') == 5)
  assert(word_match{'foo '}:match('foo')) -- spaces not allowed
  -- Test string list style.
  assert(word_match('foo bar baz'):match('foo') == 4)
  assert(not word_match('foo bar baz'):match('foo_bar'))
  assert(word_match('foo! bar? baz.', true):match('FOO!') == 5)
end

-- Tests a basic lexer with a few simple rules and no custom styles.
function test_basics()
  local lex = lexer.new('test')
  assert_default_tags(lex)
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, word_match('foo bar baz')))
  lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"')))
  lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.integer))
  local code = [[foo bar baz "foo bar baz" 123]]
  -- LuaFormatter off
  local tags = {
    {lexer.KEYWORD, 'foo'},
    {lexer.KEYWORD, 'bar'},
    {lexer.KEYWORD, 'baz'},
    {lexer.STRING, '"foo bar baz"'},
    {lexer.NUMBER, '123'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)
end

-- Tests that lexer rules are added in an ordered sequence and that modifying rules in place
-- works as expected.
function test_rule_order()
  local lex = lexer.new('test')
  lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lpeg.P('foo')))
  local code = [[foo bar]]
  -- LuaFormatter off
  local tags = {
    {lexer.IDENTIFIER, 'foo'},
    {lexer.IDENTIFIER, 'bar'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)

  -- Modify the identifier rule to not catch keywords.
  lex:modify_rule('identifier', lex:tag(lexer.IDENTIFIER, -lpeg.P('foo') * lexer.word))
  -- LuaFormatter off
  tags = {
    {lexer.KEYWORD, 'foo'},
    {lexer.IDENTIFIER, 'bar'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)
end

-- Tests a basic lexer with a couple of simple rules and a custom tag.
function test_add_tag()
  local lex = lexer.new('test')
  assert_default_tags(lex)
  lex:add_rule('keyword', lex:tag('custom', word_match('foo bar baz')))
  assert_default_tags(lex)
  local code = [[foo bar baz]]
  -- LuaFormatter off
  local tags = {
    {'custom', 'foo'},
    {'custom', 'bar'},
    {'custom', 'baz'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)
end

-- Tests word lists.
function test_word_list()
  local lex = lexer.new('test')
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:get_word_list(lexer.KEYWORD)))
  lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
  lex:add_rule('operator', lex:tag(lexer.OPERATOR, '.'))
  local code = [[foo bar.baz quux]]
  -- LuaFormatter off
  local tags = {
    {lexer.IDENTIFIER, 'foo'},
    {lexer.IDENTIFIER, 'bar'},
    {lexer.OPERATOR, '.'},
    {lexer.IDENTIFIER, 'baz'},
    {lexer.IDENTIFIER, 'quux'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, 'foo quux')
  tags[1] = {lexer.KEYWORD, 'foo'}
  tags[5] = {lexer.KEYWORD, 'quux'}
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, 'bar', true) -- append
  tags[2] = {lexer.KEYWORD, 'bar'}
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, {'bar.baz'})
  -- LuaFormatter off
  tags = {
    {lexer.IDENTIFIER, 'foo'},
    {lexer.KEYWORD, 'bar.baz'},
    {lexer.IDENTIFIER, 'quux'}
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)
end

-- Tests a simple parent lexer embedding a simple child lexer.
-- Ensures the child's custom tags are also copied over.
function test_embed()
  -- Create the parent lexer.
  local parent = lexer.new('parent')
  assert_default_tags(parent)
  parent:add_rule('identifier', parent:tag('parent', lexer.word))

  -- Create the child lexer.
  local child = lexer.new('child')
  assert_default_tags(child)
  child:add_rule('number', child:tag('child', lexer.integer))

  -- Assert the child's tags are not embedded in the parent yet.
  assert(not parent._TAGS['whitespace.' .. child._name])
  assert(not parent._extra_tags['whitespace.' .. child._name])
  assert(not parent._TAGS['child'])
  assert(not parent._extra_tags['child'])

  -- Embed the child into the parent and verify the child's tags were copied over.
  local start_rule = parent:tag('transition', lpeg.P('['))
  local end_rule = parent:tag('transition', lpeg.P(']'))
  parent:embed(child, start_rule, end_rule)
  assert_default_tags(parent)

  -- Lex some parent -> child -> parent code.
  local code = [[foo [1, 2, 3] bar]]
  -- LuaFormatter off
  local tags = {
    {'parent', 'foo'},
    {'transition', '['},
    {'child', '1'},
    {lexer.DEFAULT, ','},
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  assert_lex(parent, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  -- LuaFormatter off
  tags = {
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  local initial_style = parent._TAGS['whitespace.' .. child._name]
  assert_lex(parent, code, tags, initial_style)
end

-- Tests a simple child lexer embedding itself within a simple parent lexer.
-- Ensures the child's custom tags are also copied over.
function test_embed_into()
  -- Create the child lexer.
  local child = lexer.new('child')
  child:add_rule('number', child:tag('child', lexer.integer))

  -- Create the parent lexer.
  local parent = lexer.new('parent')
  parent:add_rule('identifier', parent:tag('parent', lexer.word))

  -- Embed the child within the parent and verify the child's custom tags were copied over.
  local start_rule = parent:tag('transition', lpeg.P('['))
  local end_rule = parent:tag('transition', lpeg.P(']'))
  parent:embed(child, start_rule, end_rule)
  assert_default_tags(parent)

  -- Verify any subsequent fold point additions to the child are copied to the parent.
  child:add_fold_point('transition', '[', ']')
  assert(parent._fold_points['transition']['['] == 1)
  assert(parent._fold_points['transition'][']'] == -1)

  -- Lex some parent -> child -> parent code.
  local code = [[foo [1, 2, 3] bar]]
  -- LuaFormatter off
  local tags = {
    {'parent', 'foo'},
    {'transition', '['},
    {'child', '1'},
    {lexer.DEFAULT, ','},
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  assert_lex(child, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  -- LuaFormatter off
  tags = {
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  local initial_style = parent._TAGS['whitespace.' .. child._name]
  assert_lex(child, code, tags, initial_style)

  -- Fold some code.
  code = [[
    foo [
      1, 2, 3
    ] bar
    baz
  ]]
  local folds = {1, -3}
  local levels = assert_fold_points(child, code, folds)
  assert(levels[3] > levels[4]) -- verify ']' is fold end point
end

-- Tests a proxy lexer that inherits from a simple parent lexer and embeds a simple child lexer.
-- Ensures both the proxy's and child's custom tags are also copied over.
function test_proxy()
  -- Create the parent lexer.
  local parent = lexer.new('parent')
  parent:add_rule('identifier', parent:tag('parent', lexer.word))

  -- Create the child lexer.
  local child = lexer.new('child')
  child:add_rule('number', child:tag('child', lexer.integer))

  -- Create the proxy lexer.
  local proxy = lexer.new('proxy', {inherit = parent})

  -- Embed the child into the parent and verify the proxy's custom tag was copied over.
  local start_rule = proxy:tag('transition', lpeg.P('['))
  local end_rule = proxy:tag('transition', lpeg.P(']'))
  proxy:embed(child, start_rule, end_rule)

  -- Lex some parent -> child -> parent code.
  local code = [[foo [1, 2, 3] bar]]
  -- LuaFormatter off
  local tags = {
    {'parent', 'foo'},
    {'transition', '['},
    {'child', '1'},
    {lexer.DEFAULT, ','},
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  assert_lex(proxy, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[ 2, 3] bar]]
  -- LuaFormatter off
  tags = {
    {'child', '2'},
    {lexer.DEFAULT, ','},
    {'child', '3'},
    {'transition', ']'},
    {'parent', 'bar'}
  }
  -- LuaFormatter on
  local initial_style = parent._TAGS['whitespace.' .. child._name]
  assert_lex(proxy, code, tags, initial_style)

  -- Verify any subsequent fold point additions to the proxy are copied to the parent.
  proxy:add_fold_point('transition', '[', ']')
  assert(parent._fold_points['transition']['['] == 1)
  assert(parent._fold_points['transition'][']'] == -1)

  -- Fold some code.
  code = [[
    foo [
      1, 2, 3
    ] bar
    baz
  ]]
  local folds = {1, -3}
  local levels = assert_fold_points(proxy, code, folds)
  assert(levels[3] > levels[4]) -- verify ']' is fold end point
end

-- Tests a lexer that inherits from another one.
function test_inherits_rules()
  local lex = lexer.new('test')
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, word_match('foo bar baz')))

  -- Verify inherited rules are used.
  local sublexer = lexer.new('test2', {inherit = lex})
  local code = [[foo bar baz]]
  -- LuaFormatter off
  local tags = {
    {lexer.KEYWORD, 'foo'},
    {lexer.KEYWORD, 'bar'},
    {lexer.KEYWORD, 'baz'}
  }
  -- LuaFormatter on
  assert_lex(sublexer, code, tags)

  -- Verify subsequently added rules are also used.
  sublexer:add_rule('keyword2', sublexer:tag(lexer.KEYWORD, lpeg.P('quux')))
  code = [[foo bar baz quux]]
  -- LuaFormatter off
  tags = {
    {lexer.KEYWORD, 'foo'},
    {lexer.KEYWORD, 'bar'},
    {lexer.KEYWORD, 'baz'},
    {lexer.KEYWORD, 'quux'}
  }
  -- LuaFormatter on
  assert_lex(sublexer, code, tags)
end

-- Tests that fold words are folded properly, even if fold words are substrings of others
-- (e.g. "if" and "endif").
function test_fold_words()
  local lex = lexer.new('test')
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, word_match('if endif')))
  lex:add_fold_point(lexer.KEYWORD, 'if', 'endif')

  local code = [[
    if foo
      bar
    endif
    ifbaz
    quuxif
  ]]
  local folds = {1, -3}
  local levels = assert_fold_points(lex, code, folds)
  assert(levels[2] == lexer.FOLD_BASE + 1)
  assert(levels[3] == lexer.FOLD_BASE + 1)
  assert(levels[4] == lexer.FOLD_BASE)
end

-- Tests folding by indentation.
function test_fold_by_indentation()
  local lex = lexer.new('test', {fold_by_indentation = true})
  local code = [[
    if foo:
      bar
    else:
      baz
  ]]
  lexer.fold_level = {lexer.FOLD_BASE} -- Scintilla normally creates this
  lexer.indent_amount = {0} -- Scintilla normally creates this
  local folds = {1, -2, 3}
  assert_fold_points(lex, code, folds)
end

-- Tests that all lexers load and lex text.
function test_loads()
  local p = io.popen('ls -1 lexers/*.lua')
  local files = p:read('*a')
  p:close()
  for file in files:gmatch('[^\n]+') do
    local lex_name = file:match('^lexers/(.+)%.lua$')
    if lex_name ~= 'lexer' then
      local lex = lexer.load(lex_name, nil, true)
      assert_default_tags(lex)
      local tags = lex:lex('test')
      assert(#tags >= 2)
    end
  end
end

-- Tests the Lua lexer.
function test_lua()
  local lua = lexer.load('lua')
  assert(lua._name == 'lua')
  assert_default_tags(lua)
  local rules = {
    'whitespace', 'keyword', 'function', 'constant', 'identifier', 'string', 'comment', 'number',
    'label', 'attribute', 'operator'
  }
  assert_rules(lua, rules)
  local tags = {
    'string.longstring', 'attribute', --
    'whitespace.lua' -- language-specific whitespace for multilang lexers
  }
  assert_extra_tags(lua, tags)

  -- Lexing tests.
  local code = [=[
    -- Comment.
    ::begin::
    local a = 1 + 2.0e3 - 0x40
    local b = "two"..[[three]]
    print(_G.print, a, string.upper(b))
  ]=]
  -- LuaFormatter off
  local tags = {
    {lexer.COMMENT, '-- Comment.'},
    {lexer.LABEL, '::begin::'},
    {lexer.KEYWORD, 'local'},
    {lexer.IDENTIFIER, 'a'},
    {lexer.OPERATOR, '='},
    {lexer.NUMBER, '1'},
    {lexer.OPERATOR, '+'},
    {lexer.NUMBER, '2.0e3'},
    {lexer.OPERATOR, '-'},
    {lexer.NUMBER, '0x40'},
    {lexer.KEYWORD, 'local'},
    {lexer.IDENTIFIER, 'b'},
    {lexer.OPERATOR, '='},
    {lexer.STRING, '"two"'},
    {lexer.OPERATOR, '..'},
    {lexer.STRING..'.longstring', '[[three]]'},
    {lexer.FUNCTION, 'print'},
    {lexer.OPERATOR, '('},
    {lexer.CONSTANT, '_G'},
    {lexer.OPERATOR, '.'},
    {lexer.IDENTIFIER, 'print'},
    {lexer.OPERATOR, ','},
    {lexer.IDENTIFIER, 'a'},
    {lexer.OPERATOR, ','},
    {lexer.FUNCTION, 'string.upper'},
    {lexer.OPERATOR, '('},
    {lexer.IDENTIFIER, 'b'},
    {lexer.OPERATOR, ')'},
    {lexer.OPERATOR, ')'}
  }
  -- LuaFormatter on
  assert_lex(lua, code, tags)

  -- Folding tests.
  code = [=[
    if foo then
      bar
    end
    for k, v in pairs(foo) do
      bar
    end
    function foo(bar)
      baz
    end
    repeat
      foo
    until bar
    --[[
      foo
    ]]
    (foo,
     bar,
     baz)
    {foo,
     bar,
     baz}
  ]=]
  local folds = {1, -3, 4, -6, 7, -9, 10, -12, 13, -15, 16, -18, 19}
  assert_fold_points(lua, code, folds)
end

-- Tests the C lexer.
function test_c()
  local c = lexer.load('ansi_c')
  assert(c._name == 'ansi_c')
  assert_default_tags(c)

  -- Lexing tests.
  local code = ([[
    /* Comment. */
    #include <stdlib.h>
    #include "lua.h"
    int main(int argc, char **argv) {
      if (NULL);
      return 0;
    }
  ]]):gsub('    ', '') -- strip indent
  -- LuaFormatter off
  local tags = {
    {lexer.COMMENT, '/* Comment. */'},
    {lexer.PREPROCESSOR, '#include'},
    {lexer.STRING, '<stdlib.h>'},
    {lexer.PREPROCESSOR, '#include'},
    {lexer.STRING, '"lua.h"'},
    {lexer.TYPE, 'int'},
    {lexer.IDENTIFIER, 'main'},
    {lexer.OPERATOR, '('},
    {lexer.TYPE, 'int'},
    {lexer.IDENTIFIER, 'argc'},
    {lexer.OPERATOR, ','},
    {lexer.TYPE, 'char'},
    {lexer.OPERATOR, '*'},
    {lexer.OPERATOR, '*'},
    {lexer.IDENTIFIER, 'argv'},
    {lexer.OPERATOR, ')'},
    {lexer.OPERATOR, '{'},
    {lexer.KEYWORD, 'if'},
    {lexer.OPERATOR, '('},
    {lexer.CONSTANT, 'NULL'},
    {lexer.OPERATOR, ')'},
    {lexer.OPERATOR, ';'},
    {lexer.KEYWORD, 'return'},
    {lexer.NUMBER, '0'},
    {lexer.OPERATOR, ';'},
    {lexer.OPERATOR, '}'}
  }
  -- LuaFormatter on
  assert_lex(c, code, tags)

  -- Folding tests.
  code = ([[
    if (foo) {
      bar;
    }
    /**
     * foo
     */
    #ifdef foo
      bar;
    #endif
  ]]):gsub('    ', '') -- strip indent
  local folds = {1, -3, 4, -6, 7}
  assert_fold_points(c, code, folds)
end

-- Tests the HTML lexer and its embedded languages.
function test_html()
  local html = lexer.load('html')
  assert(html._name == 'html')
  assert_default_tags(html)
  local rules = {
    'whitespace', 'comment', 'doctype', 'element', 'tag_close', 'attribute', -- 'equals',
    'string', 'number', 'entity'
  }
  assert_rules(html, rules)
  local tags = {
    'doctype', 'element', 'unknown_element', 'attribute', 'unknown_attribute', 'entity',
    'whitespace.html', -- HTML
    'value', 'color', 'unit', 'at_rule', 'whitespace.css', -- CSS
    'whitespace.javascript', -- JS
    'whitespace.coffeescript' -- CoffeeScript
  }
  assert_extra_tags(html, tags)
  assert_children(html, {'css', 'javascript', 'coffeescript'})

  -- Lexing tests.
  local code = [[
    <!DOCTYPE html>
    <!-- Comment. -->
    <html>
      <head>
        <style type="text/css">
          /* Another comment. */
          h1:hover {
            color: red;
            border: 1px solid #0000FF;
          }
        </style>
        <script type="text/javascript">
          /* A third comment. */
          var a = 1 + 2.0e3 - 0x40;
          var b = "two" + `three`;
          var c = /pattern/i;
        //</script>
      </head>
      <bod/>
    </html>
  ]]
  -- LuaFormatter off
  local tags = {
    {'doctype', '<!DOCTYPE html>'},
    {lexer.COMMENT, '<!-- Comment. -->'},
    {'element', '<html'},
    {'element', '>'},
    {'element', '<head'},
    {'element', '>'},
    {'element', '<style'},
    {'attribute', 'type'},
    {lexer.OPERATOR, '='},
    {lexer.STRING, '"text/css"'},
    {'element', '>'},
    {lexer.COMMENT, '/* Another comment. */'},
    {lexer.IDENTIFIER, 'h1'},
    {'pseudoclass', ':hover'},
    {lexer.OPERATOR, '{'},
    {'property', 'color'},
    {lexer.OPERATOR, ':'},
    {'value', 'red'},
    {lexer.OPERATOR, ';'},
    {'property', 'border'},
    {lexer.OPERATOR, ':'},
    {lexer.NUMBER, '1'},
    {'unit', 'px'},
    {'value', 'solid'},
    {'color', '#0000FF'},
    {lexer.OPERATOR, ';'},
    {lexer.OPERATOR, '}'},
    {'element', '</style'},
    {'element', '>'},
    {'element', '<script'},
    {'attribute', 'type'},
    {lexer.OPERATOR, '='},
    {lexer.STRING, '"text/javascript"'},
    {'element', '>'},
    {lexer.COMMENT, '/* A third comment. */'},
    {lexer.KEYWORD, 'var'},
    {lexer.IDENTIFIER, 'a'},
    {lexer.OPERATOR, '='},
    {lexer.NUMBER, '1'},
    {lexer.OPERATOR, '+'},
    {lexer.NUMBER, '2.0e3'},
    {lexer.OPERATOR, '-'},
    {lexer.NUMBER, '0x40'},
    {lexer.OPERATOR, ';'},
    {lexer.KEYWORD, 'var'},
    {lexer.IDENTIFIER, 'b'},
    {lexer.OPERATOR, '='},
    {lexer.STRING, '"two"'},
    {lexer.OPERATOR, '+'},
    {lexer.STRING, '`three`'},
    {lexer.OPERATOR, ';'},
    {lexer.KEYWORD, 'var'},
    {lexer.IDENTIFIER, 'c'},
    {lexer.OPERATOR, '='},
    {lexer.REGEX, '/pattern/i'},
    {lexer.OPERATOR, ';'},
    {lexer.COMMENT, '//'},
    {'element', '</script'},
    {'element', '>'},
    {'element', '</head'},
    {'element', '>'},
    {'unknown_element', '<bod'},
    {'element', '/>'},
    {'element', '</html'},
    {'element', '>'}
  }
  -- LuaFormatter on
  assert_lex(html, code, tags)

  -- Folding tests.
  local symbols = {'<', '<!--', '-->', '{', '}', '/*', '*/', '//'}
  for i = 1, #symbols do assert(html._fold_points._symbols[symbols[i]]) end
  assert(html._fold_points['element']['<'])
  assert(html._fold_points['unknown_element']['<'])
  assert(html._fold_points[lexer.COMMENT]['<!--'])
  assert(html._fold_points[lexer.COMMENT]['-->'])
  assert(html._fold_points[lexer.OPERATOR]['{'])
  assert(html._fold_points[lexer.OPERATOR]['}'])
  assert(html._fold_points[lexer.COMMENT]['/*'])
  assert(html._fold_points[lexer.COMMENT]['*/'])
  assert(html._fold_points[lexer.COMMENT]['//'])
  code = [[
    <html>
      foo
    </html>
    <body/>
    <style type="text/css">
      h1 {
        foo;
      }
    </style>
    <script type="text/javascript">
      function foo() {
        bar;
      }
    </script>
    h1 {
      foo;
    }
    function foo() {
      bar;
    }
  ]]
  local folds = {1, -3, 5, 6, -8, -9, 10, 11, -13}
  local levels = assert_fold_points(html, code, folds)
  assert(levels[3] > levels[4]) -- </html> is ending fold point
end

-- Tests the PHP lexer.
function test_php()
  local php = lexer.load('php')
  assert(php._name == 'php')
  assert_default_tags(php)
  assert_extra_tags(php, {'whitespace.php', 'php_tag'})

  -- Lexing tests
  -- Starting in HTML.
  local code = [[<h1><?php echo "hi"; ?></h1>]]
  -- LuaFormatter off
  local tags = {
    {'element', '<h1'},
    {'element', '>'},
    {'php_tag', '<?php '},
    {lexer.KEYWORD, 'echo'},
    {lexer.STRING, '"hi"'},
    {lexer.OPERATOR, ';'},
    {'php_tag', '?>'},
    {'element', '</h1'},
    {'element', '>'}
  }
  -- LuaFormatter on
  local initial_style = php._TAGS['whitespace.html']
  assert_lex(php, code, tags, initial_style)
  initial_style = php._TAGS['default'] -- also test non-ws init style
  assert_lex(php, code, tags, initial_style)
  initial_style = php._TAGS['default'] -- also test non-ws init style
  assert_lex(php, code, tags, initial_style)
  -- Starting in PHP.
  code = [[echo "hi";]]
  initial_style = php._TAGS['whitespace.php']
  -- LuaFormatter off
  tags = {
    {lexer.KEYWORD, 'echo'},
    {lexer.STRING, '"hi"'},
    {lexer.OPERATOR, ';'},
  }
  -- LuaFormatter on
  assert_lex(php, code, tags, initial_style)

  -- Folding tests.
  local symbols = {'<?', '?>', '/*', '*/', '//', '#', '{', '}', '(', ')'}
  for i = 1, #symbols do assert(php._fold_points._symbols[symbols[i]]) end
  assert(php._fold_points['php_tag']['<?'])
  assert(php._fold_points['php_tag']['?>'])
  assert(php._fold_points[lexer.COMMENT]['/*'])
  assert(php._fold_points[lexer.COMMENT]['*/'])
  assert(php._fold_points[lexer.COMMENT]['//'])
  assert(php._fold_points[lexer.COMMENT]['#'])
  assert(php._fold_points[lexer.OPERATOR]['{'])
  assert(php._fold_points[lexer.OPERATOR]['}'])
  assert(php._fold_points[lexer.OPERATOR]['('])
  assert(php._fold_points[lexer.OPERATOR][')'])
end

-- Tests the Ruby lexer.
function test_ruby()
  local ruby = lexer.load('ruby')

  -- Lexing tests.
  local code = [[
    # Comment.
    require "foo"
    $a = 1 + 2.0e3 - 0x40 if true
    b = "two" + %q[three]
    puts :c
  ]]
  -- LuaFormatter off
  local tags = {
    {lexer.COMMENT, '# Comment.'},
    {lexer.FUNCTION, 'require'},
    {lexer.STRING, '"foo"'},
    {lexer.VARIABLE, '$a'},
    {lexer.OPERATOR, '='},
    {lexer.NUMBER, '1'},
    {lexer.OPERATOR, '+'},
    {lexer.NUMBER, '2.0e3'},
    {lexer.OPERATOR, '-'},
    {lexer.NUMBER, '0x40'},
    {lexer.KEYWORD, 'if'},
    {lexer.KEYWORD, 'true'},
    {lexer.IDENTIFIER, 'b'},
    {lexer.OPERATOR, '='},
    {lexer.STRING, '"two"'},
    {lexer.OPERATOR, '+'},
    {lexer.STRING, '%q[three]'},
    {lexer.FUNCTION, 'puts'},
    {'symbol', ':c'}
  }
  -- LuaFormatter on
  assert_lex(ruby, code, tags)

  -- Folding tests.
  local fold_keywords = {
    begin = 1, class = 1, def = 1, ['do'] = 1, ['for'] = 1, ['module'] = 1, case = 1,
    ['if'] = function() end, ['while'] = function() end, ['unless'] = function() end,
    ['until'] = function() end, ['end'] = -1
  }
  for k, v in pairs(fold_keywords) do
    assert(ruby._fold_points._symbols[k])
    if type(v) == 'number' then
      assert(ruby._fold_points[lexer.KEYWORD][k] == v)
    else
      assert(type(ruby._fold_points[lexer.KEYWORD][k]) == 'function')
    end
  end
  local fold_operators = {'(', ')', '[', ']', '{', '}'}
  for i = 1, #fold_operators do
    assert(ruby._fold_points._symbols[fold_operators[i]])
    assert(ruby._fold_points[lexer.OPERATOR][fold_operators[i]])
  end
  code = [=[
    class Foo
      bar
    end
    foo.each do |v|
      bar
    end
    def foo(bar)
      baz
    end
    =begin
      foo
    =end
    (foo,
     bar,
     baz)
    [foo,
     bar,
     baz]
    {foo,
     bar,
     baz}
  ]=]
  local folds = {1, -3, 4, -6, 7, -9, 10, -12, 13, -15, 16, -18, 19, -21}
  assert_fold_points(ruby, code, folds)
end

-- Tests the Ruby and Rails lexers and tests lexer caching and lack of caching.
-- The Rails lexer inherits from Ruby and modifies some of its rules. Verify the Ruby lexer
-- is unaffected.
function test_ruby_and_rails()
  local ruby = lexer.load('ruby', nil, true)
  local rails = lexer.load('rails', nil, true)
  local code = [[
    class Foo < ActiveRecord::Base
      has_one :bar
    end
  ]]
  -- LuaFormatter off
  local ruby_tags = {
    {lexer.KEYWORD, 'class'},
    {lexer.IDENTIFIER, 'Foo'},
    {lexer.OPERATOR, '<'},
    {lexer.IDENTIFIER, 'ActiveRecord'},
    {lexer.OPERATOR, ':'},
    {lexer.OPERATOR, ':'},
    {lexer.IDENTIFIER, 'Base'},
    {lexer.IDENTIFIER, 'has_one'},
    {'symbol', ':bar'},
    {lexer.KEYWORD, 'end'}
  }
  -- LuaFormatter on
  assert_lex(ruby, code, ruby_tags)

  -- LuaFormatter off
  local rails_tags = {
    {lexer.KEYWORD, 'class'},
    {lexer.IDENTIFIER, 'Foo'},
    {lexer.OPERATOR, '<'},
    {lexer.IDENTIFIER, 'ActiveRecord'},
    {lexer.OPERATOR, ':'},
    {lexer.OPERATOR, ':'},
    {lexer.IDENTIFIER, 'Base'},
    {lexer.FUNCTION, 'has_one'},
    {'symbol', ':bar'},
    {lexer.KEYWORD, 'end'}
  }
  -- LuaFormatter on
  assert_lex(rails, code, rails_tags)
end

-- Tests the RHTML lexer, which is a proxy for HTML and Rails.
function test_rhtml()
  local rhtml = lexer.load('rhtml')

  -- Lexing tests.
  -- Start in HTML.
  local code = [[<h1><% puts "hi" %></h1>]]
  -- LuaFormatter off
  local rhtml_tags = {
    {'element', '<h1'},
    {'element', '>'},
    {'rhtml_tag', '<%'},
    {lexer.FUNCTION, 'puts'},
    {lexer.STRING, '"hi"'},
    {'rhtml_tag', '%>'},
    {'element', '</h1'},
    {'element', '>'}
  }
  -- LuaFormatter on
  local initial_style = rhtml._TAGS['whitespace.html']
  assert_lex(rhtml, code, rhtml_tags, initial_style)
  -- Start in Ruby.
  code = [[puts "hi"]]
  -- LuaFormatter off
  rhtml_tags = {
    {lexer.FUNCTION, 'puts'},
    {lexer.STRING, '"hi"'}
  }
  -- LuaFormatter on
  initial_style = rhtml._TAGS['whitespace.rails']
  assert_lex(rhtml, code, rhtml_tags, initial_style)
end

-- Tests folding with complex keywords and case-insensitivity.
function test_vb_folding()
  local vb = lexer.load('vb')

  local code = [[
    Sub Foo()
      If bar Then

      End If
    End Sub

    sub baz()

    end sub
  ]]
  local folds = {1, 2, -4, -5, 7, -9}
  assert_fold_points(vb, code, folds)
end

function test_legacy()
  local lex = lexer.new('test')
  local ws = lexer.token(lexer.WHITESPACE, lexer.space^1)
  lex:add_rule('whitespace', ws) -- should call lex:modify_rule()
  assert(#lex._rules == 1 + lexer.num_user_word_lists)
  assert(lex._rules['whitespace'] == ws)
  lex:add_rule('keyword', lexer.token(lexer.KEYWORD, lexer.word_match('foo bar baz')))
  lex:add_rule('number', lexer.token(lexer.NUMBER, lexer.number))
  lex:add_style('whatever', lexer.styles.keyword .. {fore = lexer.colors.red, italic = true})
  local code = [[foo 1 bar 2 baz 3]]
  -- LuaFormatter off
  local tags = {
    {lexer.KEYWORD, 'foo'},
    {lexer.NUMBER, '1'},
    {lexer.KEYWORD, 'bar'},
    {lexer.NUMBER, '2'},
    {lexer.KEYWORD, 'baz'},
    {lexer.NUMBER, '3'},
  }
  -- LuaFormatter on
  assert_lex(lex, code, tags)
end

-- Run tests.
print('Starting test suite.')
local tests = {}
if #arg == 0 then
  for k, v in pairs(_G) do
    if k:find('^test_') and type(v) == 'function' then tests[#tests + 1] = k end
  end
else
  for i = 1, #arg do if type(_G[arg[i]]) == 'function' then tests[#tests + 1] = arg[i] end end
end
table.sort(tests)
local failed = 0
for i = 1, #tests do
  print(string.format('Running %s.', tests[i]))
  local ok, errmsg = xpcall(_G[tests[i]], function(errmsg)
    print(string.format('Failed!\n%s', debug.traceback(errmsg, 3)))
    failed = failed + 1
  end)
end
print(string.format('%d/%d tests passed', #tests - failed, #tests))
os.exit(failed == 0 and 0 or 1)
