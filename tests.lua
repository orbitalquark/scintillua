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
    'whitespace', 'comment', 'string', 'number', 'keyword', 'identifier', 'operator', 'error',
    'preprocessor', 'constant', 'variable', 'function', 'class', 'type', 'label', 'regex',
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
  if not lex._lexer and not lex._no_user_word_lists then
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
-- @param expected_tags The list of expected tag names followed by the substring of code matched.
--   Whitespace tags are ignored for the sake of simplicity. Do not include them.
-- @param initial_style Optional current style. This is used for determining which language to
--   start in in a multiple-language lexer.
-- @usage assert_lex(lua, "print('hi')", {lexer.FUNCTION_BUILTIN, 'print', lexer.OPERATOR, '(',
--   lexer.STRING, "'hi'", lexer.OPERATOR, ')'}})
function assert_lex(lex, code, expected_tags, initial_style)
  if lex._lexer then lex = lex._lexer end -- note: lexer.load() does this
  local tags = lex:lex(code, initial_style or lex._TAGS['whitespace.' .. lex._name])
  local j = 1
  for i = 1, #tags, 2 do
    if not tags[i]:find('^whitespace') then
      local tag = tags[i]
      local text = code:sub(tags[i - 1] or 0, tags[i + 1] - 1)
      assert(tag == expected_tags[j] and text == expected_tags[j + 1], string.format(
        "('%s', '%s') ~= ('%s', '%s')", tag, text, expected_tags[j], expected_tags[j + 1]))
      j = j + 2
    end
  end
  if j - 1 ~= #expected_tags then
    error(string.format("('%s', '%s') not found", expected_tags[j], expected_tags[j + 1]))
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
  local levels = lex:fold(code, 1, lexer.FOLD_BASE)
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
  assert(lexer.starts_line('#', true):match(' #foo', 2) == 3)
  assert(lexer.starts_line('#', true):match('\t#foo', 2) == 3)
  assert(lexer.starts_line('#', true):match('\n\t#foo', 3) == 4)
  assert(not lexer.starts_line('#', true):match('\n.#foo', 3))
end

function test_after_set()
  local set = '=,'
  local regex = lexer.range('/')
  assert(lexer.after_set(set, regex):match('/foo'))
  assert(lexer.after_set(set, regex):match('/foo/'))
  assert(lexer.after_set(set, regex):match('foo=/bar/', 5))
  assert(lexer.after_set(set, regex):match('foo=\n/bar/', 6))
  assert(lexer.after_set(set, regex):match('foo, /bar/', 6))
  assert(not lexer.after_set(set, regex):match('foo/bar', 4))
  assert(not lexer.after_set(set, regex):match('foo / bar', 5))
  assert(lexer.after_set(set .. ' ', regex):match('foo / bar', 5))
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
  local tags = {
    lexer.KEYWORD, 'foo', --
    lexer.KEYWORD, 'bar', --
    lexer.KEYWORD, 'baz', --
    lexer.STRING, '"foo bar baz"', --
    lexer.NUMBER, '123'
  }
  assert_lex(lex, code, tags)
end

-- Tests that lexer rules are added in an ordered sequence and that modifying rules in place
-- works as expected.
function test_rule_order()
  local lex = lexer.new('test')
  lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lpeg.P('foo')))
  local code = [[foo bar]]
  local tags = {lexer.IDENTIFIER, 'foo', lexer.IDENTIFIER, 'bar'}
  assert_lex(lex, code, tags)

  -- Modify the identifier rule to not catch keywords.
  lex:modify_rule('identifier', -lpeg.P('foo') * lex:tag(lexer.IDENTIFIER, lexer.word))
  tags = {lexer.KEYWORD, 'foo', lexer.IDENTIFIER, 'bar'}
  assert_lex(lex, code, tags)
end

-- Tests a basic lexer with a couple of simple rules and a custom tag.
function test_add_tag()
  local lex = lexer.new('test')
  assert_default_tags(lex)
  lex:add_rule('keyword', lex:tag('custom', word_match('foo bar baz')))
  assert_default_tags(lex)
  local code = [[foo bar baz]]
  local tags = {'custom', 'foo', 'custom', 'bar', 'custom', 'baz'}
  assert_lex(lex, code, tags)
end

-- Tests word lists.
function test_word_list()
  local lex = lexer.new('test')
  lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:get_word_list(lexer.KEYWORD)))
  lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
  lex:add_rule('operator', lex:tag(lexer.OPERATOR, '.'))
  local code = [[foo bar.baz quux]]
  local tags = {
    lexer.IDENTIFIER, 'foo', --
    lexer.IDENTIFIER, 'bar', --
    lexer.OPERATOR, '.', --
    lexer.IDENTIFIER, 'baz', --
    lexer.IDENTIFIER, 'quux'
  }
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, 'foo quux')
  tags[1 * 2 - 1], tags[1 * 2] = lexer.KEYWORD, 'foo'
  tags[5 * 2 - 1], tags[5 * 2] = lexer.KEYWORD, 'quux'
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, 'bar', true) -- append
  tags[2 * 2 - 1], tags[2 * 2] = lexer.KEYWORD, 'bar'
  assert_lex(lex, code, tags)

  lex:set_word_list(lexer.KEYWORD, {'bar.baz'})
  tags = {lexer.IDENTIFIER, 'foo', lexer.KEYWORD, 'bar.baz', lexer.IDENTIFIER, 'quux'}
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
  local tags = {
    'parent', 'foo', --
    'transition', '[', --
    'child', '1', --
    lexer.DEFAULT, ',', --
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(parent, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  tags = {
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
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
  local tags = {
    'parent', 'foo', --
    'transition', '[', --
    'child', '1', --
    lexer.DEFAULT, ',', --
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(child, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  tags = {
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
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
  local tags = {
    'parent', 'foo', --
    'transition', '[', --
    'child', '1', --
    lexer.DEFAULT, ',', --
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(proxy, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[ 2, 3] bar]]
  tags = {
    'child', '2', --
    lexer.DEFAULT, ',', --
    'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
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
  local tags = {lexer.KEYWORD, 'foo', lexer.KEYWORD, 'bar', lexer.KEYWORD, 'baz'}
  assert_lex(sublexer, code, tags)

  -- Verify subsequently added rules are also used.
  sublexer:add_rule('keyword2', sublexer:tag(lexer.KEYWORD, lpeg.P('quux')))
  code = [[foo bar baz quux]]
  tags = {lexer.KEYWORD, 'foo', lexer.KEYWORD, 'bar', lexer.KEYWORD, 'baz', lexer.KEYWORD, 'quux'}
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
    'keyword', 'function', 'constant', 'identifier', 'string', 'comment', 'number', 'label',
    'attribute', 'operator'
  }
  assert_rules(lua, rules)
  local tags = {
    lexer.STRING .. '.longstring', --
    'whitespace.lua' -- language-specific whitespace for multilang lexers
  }
  assert_extra_tags(lua, tags)

  -- Lexing tests.
  local code = [=[
    --[[ Comment. ]]--
    ::begin::
    local a <const> = -1 + 2.0e3 - 0x40
    local b = "two"..[[three]] .. 'four\''
    c ={_G.print, type = foo{math.pi}}
    print(string.upper'a', b:upper())
  ]=]
  tags = {
    lexer.COMMENT, '--[[ Comment. ]]', lexer.COMMENT, '--', --
    lexer.LABEL, '::begin::', --
    lexer.KEYWORD, 'local', --
    lexer.IDENTIFIER, 'a', --
    lexer.ATTRIBUTE, '<const>', --
    lexer.OPERATOR, '=', --
    lexer.NUMBER, '-1', --
    lexer.OPERATOR, '+', --
    lexer.NUMBER, '2.0e3', --
    lexer.OPERATOR, '-', --
    lexer.NUMBER, '0x40', --
    lexer.KEYWORD, 'local', --
    lexer.IDENTIFIER, 'b', --
    lexer.OPERATOR, '=', --
    lexer.STRING, '"two"', --
    lexer.OPERATOR, '..', --
    lexer.STRING .. '.longstring', '[[three]]', --
    lexer.OPERATOR, '..', --
    lexer.STRING, [['four\'']], --
    lexer.IDENTIFIER, 'c', --
    lexer.OPERATOR, '=', --
    lexer.OPERATOR, '{', --
    lexer.CONSTANT_BUILTIN, '_G', lexer.OPERATOR, '.', lexer.IDENTIFIER, 'print', --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'type', --
    lexer.OPERATOR, '=', --
    lexer.FUNCTION, 'foo', --
    lexer.OPERATOR, '{', --
    lexer.CONSTANT_BUILTIN, 'math.pi', --
    lexer.OPERATOR, '}', --
    lexer.OPERATOR, '}', --
    lexer.FUNCTION_BUILTIN, 'print', --
    lexer.OPERATOR, '(', --
    lexer.FUNCTION_BUILTIN, 'string.upper', --
    lexer.STRING, "'a'", --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'b', --
    lexer.OPERATOR, ':', --
    lexer.FUNCTION_METHOD, 'upper', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ')'
  }
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
    #include <stdio.h>
    #include "lua.h"
    #  define INT_MAX_ 1
    int main(int argc, char **argv) {
    begin:
      if (NULL) // comment
        printf("%ld %f %s %i", 1l, 1.0e-1f, L"foo", INT_MAX);
      foo.free, foo->free(), free(foo);
      return 0x0?argc:0;
    }
  ]]):gsub('    ', '') -- strip indent
  local tags = {
    lexer.COMMENT, '/* Comment. */', --
    lexer.PREPROCESSOR, '#include', lexer.STRING, '<stdio.h>', --
    lexer.PREPROCESSOR, '#include', lexer.STRING, '"lua.h"', --
    lexer.PREPROCESSOR, '#  define', lexer.IDENTIFIER, 'INT_MAX_', lexer.NUMBER, '1', --
    lexer.TYPE, 'int', lexer.FUNCTION, 'main', --
    lexer.OPERATOR, '(', --
    lexer.TYPE, 'int', lexer.IDENTIFIER, 'argc', --
    lexer.OPERATOR, ',', --
    lexer.TYPE, 'char', lexer.OPERATOR, '*', lexer.OPERATOR, '*', lexer.IDENTIFIER, 'argv', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, '{', --
    lexer.LABEL, 'begin:', --
    lexer.KEYWORD, 'if', --
    lexer.OPERATOR, '(', lexer.CONSTANT_BUILTIN, 'NULL', lexer.OPERATOR, ')', --
    lexer.COMMENT, '// comment', --
    lexer.FUNCTION_BUILTIN, 'printf', --
    lexer.OPERATOR, '(', --
    lexer.STRING, '"%ld %f %s %i"', --
    lexer.OPERATOR, ',', --
    lexer.NUMBER, '1l', --
    lexer.OPERATOR, ',', --
    lexer.NUMBER, '1.0e-1f', --
    lexer.OPERATOR, ',', --
    lexer.STRING, 'L"foo"', --
    lexer.OPERATOR, ',', --
    lexer.CONSTANT_BUILTIN, 'INT_MAX', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.IDENTIFIER, 'foo', lexer.OPERATOR, '.', lexer.IDENTIFIER, 'free', --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'foo', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '>', --
    lexer.FUNCTION_METHOD, 'free', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ',', --
    lexer.FUNCTION_BUILTIN, 'free', --
    lexer.OPERATOR, '(', --
    lexer.IDENTIFIER, 'foo', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.KEYWORD, 'return', --
    lexer.NUMBER, '0x0', --
    lexer.OPERATOR, '?', --
    lexer.IDENTIFIER, 'argc', -- should not be a label
    lexer.OPERATOR, ':', --
    lexer.NUMBER, '0', --
    lexer.OPERATOR, ';', --
    lexer.OPERATOR, '}'
  }
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
    'comment', 'doctype', 'tag', 'tag_close', 'attribute', -- 'equals',
    'string', 'number', 'entity'
  }
  assert_rules(html, rules)
  local tags = {
    lexer.TAG .. '.doctype', lexer.TAG .. '.unknown', lexer.ATTRIBUTE .. '.unknown', 'entity', --
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
      <HEAD>
        <style type="text/css">
          @charset "utf8"
          /* Another comment. */
          h1:hover, h2::first-line {
            color: darkred;
            border: 1px solid #0000FF;
            background: url("/images/image.jpg");
          }
        </style>
        <script type="text/javascript">
          /* A third comment. */
          var a = 1 + 2.0e3 - 0x40;
          var b = "two" + `three`;
          var c = /pattern/i;
          foo(eval(arguments), bar.baz(), Object);
        </script>
      </HEAD>
      <bod clss = "unknown">
      <hr tabindex=1/> &copy;
    </html>
  ]]
  local tag_chars = lexer.TAG .. '.chars'
  tags = {
    lexer.TAG .. '.doctype', '<!DOCTYPE html>', --
    lexer.COMMENT, '<!-- Comment. -->', --
    tag_chars, '<', lexer.TAG, 'html', tag_chars, '>', --
    tag_chars, '<', lexer.TAG, 'HEAD', tag_chars, '>', --
    tag_chars, '<', --
    lexer.TAG, 'style', --
    lexer.ATTRIBUTE, 'type', lexer.OPERATOR, '=', lexer.STRING, '"text/css"', --
    tag_chars, '>', --
    'at_rule', '@charset', lexer.STRING, '"utf8"', --
    lexer.COMMENT, '/* Another comment. */', --
    lexer.IDENTIFIER, 'h1', 'pseudoclass', ':hover', --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'h2', 'pseudoelement', '::first-line', --
    lexer.OPERATOR, '{', --
    'property', 'color', lexer.OPERATOR, ':', 'color', 'darkred', lexer.OPERATOR, ';', --
    'property', 'border', --
    lexer.OPERATOR, ':', --
    lexer.NUMBER, '1', 'unit', 'px', 'value', 'solid', 'color', '#0000FF', --
    lexer.OPERATOR, ';', --
    'property', 'background', --
    lexer.OPERATOR, ':', --
    lexer.FUNCTION_BUILTIN, 'url', --
    lexer.OPERATOR, '(', --
    lexer.STRING, '"/images/image.jpg"', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.OPERATOR, '}', --
    tag_chars, '</', lexer.TAG, 'style', tag_chars, '>', --
    tag_chars, '<', --
    lexer.TAG, 'script', --
    lexer.ATTRIBUTE, 'type', lexer.OPERATOR, '=', lexer.STRING, '"text/javascript"', --
    tag_chars, '>', --
    lexer.COMMENT, '/* A third comment. */', --
    lexer.KEYWORD, 'var', --
    lexer.IDENTIFIER, 'a', --
    lexer.OPERATOR, '=', --
    lexer.NUMBER, '1', --
    lexer.OPERATOR, '+', --
    lexer.NUMBER, '2.0e3', --
    lexer.OPERATOR, '-', --
    lexer.NUMBER, '0x40', --
    lexer.OPERATOR, ';', --
    lexer.KEYWORD, 'var', --
    lexer.IDENTIFIER, 'b', --
    lexer.OPERATOR, '=', --
    lexer.STRING, '"two"', --
    lexer.OPERATOR, '+', --
    lexer.STRING, '`three`', --
    lexer.OPERATOR, ';', --
    lexer.KEYWORD, 'var', --
    lexer.IDENTIFIER, 'c', --
    lexer.OPERATOR, '=', --
    lexer.REGEX, '/pattern/i', --
    lexer.OPERATOR, ';', --
    lexer.FUNCTION, 'foo', --
    lexer.OPERATOR, '(', --
    lexer.FUNCTION_BUILTIN, 'eval', --
    lexer.OPERATOR, '(', --
    lexer.CONSTANT_BUILTIN, 'arguments', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'bar', --
    lexer.OPERATOR, '.', --
    lexer.FUNCTION_METHOD, 'baz', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ',', --
    lexer.TYPE, 'Object', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    tag_chars, '</', lexer.TAG, 'script', tag_chars, '>', --
    tag_chars, '</', lexer.TAG, 'HEAD', tag_chars, '>', --
    tag_chars, '<', --
    lexer.TAG .. '.unknown', 'bod', --
    lexer.ATTRIBUTE .. '.unknown', 'clss', lexer.DEFAULT, '=', lexer.STRING, '"unknown"', --
    tag_chars, '>', --
    tag_chars, '<', --
    lexer.TAG .. '.single', 'hr', --
    lexer.ATTRIBUTE, 'tabindex', lexer.DEFAULT, '=', lexer.NUMBER, '1', --
    tag_chars, '/>', --
    'entity', '&copy;', --
    tag_chars, '</', lexer.TAG, 'html', tag_chars, '>'
  }
  assert_lex(html, code, tags)

  -- Folding tests.
  local symbols = {'<', '<!--', '-->', '{', '}', '/*', '*/', '//'}
  for i = 1, #symbols do assert(html._fold_points._symbols[symbols[i]]) end
  assert(html._fold_points[lexer.TAG .. '.chars']['<'])
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
  assert_extra_tags(php, {'whitespace.php', lexer.TAG .. '.php'})

  -- Lexing tests
  -- Starting in HTML.
  local code = [[<h1><?php echo "hi" . PHP_OS . foo() . bar->baz(); ?></h1>]]
  local tag_chars = lexer.TAG .. '.chars'
  local tags = {
    tag_chars, '<', lexer.TAG, 'h1', tag_chars, '>', --
    lexer.TAG .. '.php', '<?php ', --
    lexer.KEYWORD, 'echo', --
    lexer.STRING, '"hi"', --
    lexer.OPERATOR, '.', --
    lexer.CONSTANT_BUILTIN, 'PHP_OS', --
    lexer.OPERATOR, '.', --
    lexer.FUNCTION, 'foo', lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, '.', --
    lexer.IDENTIFIER, 'bar', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '>', --
    lexer.FUNCTION_METHOD, 'baz', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.TAG .. '.php', '?>', --
    tag_chars, '</', lexer.TAG, 'h1', tag_chars, '>'
  }
  local initial_style = php._TAGS['whitespace.html']
  assert_lex(php, code, tags, initial_style)
  initial_style = php._TAGS['default'] -- also test non-ws init style
  assert_lex(php, code, tags, initial_style)
  initial_style = php._TAGS['default'] -- also test non-ws init style
  assert_lex(php, code, tags, initial_style)
  -- Starting in PHP.
  code = [[echo "hi";]]
  initial_style = php._TAGS['whitespace.php']
  tags = {lexer.KEYWORD, 'echo', lexer.STRING, '"hi"', lexer.OPERATOR, ';'}
  assert_lex(php, code, tags, initial_style)

  -- Folding tests.
  local symbols = {'<?', '?>', '/*', '*/', '//', '#', '{', '}', '(', ')'}
  for i = 1, #symbols do assert(php._fold_points._symbols[symbols[i]]) end
  assert(php._fold_points[lexer.TAG .. '.php']['<?'])
  assert(php._fold_points[lexer.TAG .. '.php']['?>'])
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
    b = "two" + %q[three] + <<-FOUR
      four
    FOUR
    puts :c, foo.puts
  ]]
  local tags = {
    lexer.COMMENT, '# Comment.', --
    lexer.FUNCTION_BUILTIN, 'require', lexer.STRING, '"foo"', --
    lexer.VARIABLE, '$a', --
    lexer.OPERATOR, '=', --
    lexer.NUMBER, '1', --
    lexer.OPERATOR, '+', --
    lexer.NUMBER, '2.0e3', --
    lexer.OPERATOR, '-', --
    lexer.NUMBER, '0x40', --
    lexer.KEYWORD, 'if', --
    lexer.KEYWORD, 'true', --
    lexer.IDENTIFIER, 'b', --
    lexer.OPERATOR, '=', --
    lexer.STRING, '"two"', --
    lexer.OPERATOR, '+', --
    lexer.STRING, '%q[three]', --
    lexer.OPERATOR, '+', --
    lexer.STRING, '<<-FOUR\n      four\n    FOUR', --
    lexer.FUNCTION_BUILTIN, 'puts', 'symbol', ':c', --
    lexer.OPERATOR, ',', --
    lexer.IDENTIFIER, 'foo', lexer.OPERATOR, '.', lexer.IDENTIFIER, 'puts'
  }
  assert_lex(ruby, code, tags)

  -- Folding tests.
  local fold_keywords = {
    begin = 1, class = 1, def = 1, ['do'] = 1, ['for'] = 1, module = 1, case = 1,
    ['if'] = function() end, ['while'] = function() end, unless = function() end,
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

-- Tests the Ruby and Rails lexers.
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
  local ruby_tags = {
    lexer.KEYWORD, 'class', --
    lexer.IDENTIFIER, 'Foo', --
    lexer.OPERATOR, '<', --
    lexer.IDENTIFIER, 'ActiveRecord', --
    lexer.OPERATOR, ':', lexer.OPERATOR, ':', --
    lexer.IDENTIFIER, 'Base', --
    lexer.IDENTIFIER, 'has_one', -- function.builtin in rails
    'symbol', ':bar', --
    lexer.KEYWORD, 'end'
  }
  assert_lex(ruby, code, ruby_tags)

  local rails_tags = {
    lexer.KEYWORD, 'class', --
    lexer.IDENTIFIER, 'Foo', --
    lexer.OPERATOR, '<', --
    lexer.IDENTIFIER, 'ActiveRecord', --
    lexer.OPERATOR, ':', lexer.OPERATOR, ':', --
    lexer.IDENTIFIER, 'Base', --
    lexer.FUNCTION_BUILTIN, 'has_one', --
    'symbol', ':bar', --
    lexer.KEYWORD, 'end'
  }
  assert_lex(rails, code, rails_tags)
end

-- Tests the RHTML lexer, which is a proxy for HTML and Rails.
function test_rhtml()
  local rhtml = lexer.load('rhtml')

  -- Lexing tests.
  -- Start in HTML.
  local code = [[<h1><% puts "hi" + link_to "foo" @foo %></h1>]]
  local tag_chars = lexer.TAG .. '.chars'
  local rhtml_tags = {
    tag_chars, '<', lexer.TAG, 'h1', tag_chars, '>', --
    'rhtml_tag', '<%', --
    lexer.FUNCTION_BUILTIN, 'puts', lexer.STRING, '"hi"', --
    lexer.OPERATOR, '+', --
    lexer.FUNCTION_BUILTIN, 'link_to', lexer.STRING, '"foo"', lexer.VARIABLE, '@foo', --
    'rhtml_tag', '%>', --
    tag_chars, '</', lexer.TAG, 'h1', tag_chars, '>'
  }
  local initial_style = rhtml._TAGS['whitespace.html']
  assert_lex(rhtml, code, rhtml_tags, initial_style)
  -- Start in Ruby.
  code = [[puts "hi" + link_to "foo" @foo]]
  rhtml_tags = {
    lexer.FUNCTION_BUILTIN, 'puts', lexer.STRING, '"hi"', --
    lexer.OPERATOR, '+', --
    lexer.FUNCTION_BUILTIN, 'link_to', lexer.STRING, '"foo"', lexer.VARIABLE, '@foo'
  }
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

function test_makefile()
  local makefile = lexer.load('makefile')
  local code = ([[
    # Comment.
    .DEFAULT_GOAL := all
    foo ?= bar=baz
    all: $(foo)
    $(foo): ; echo 'hi'

    .PHONY: docs
    define build-cc =
      $(CC) ${CFLAGS} -c $< -o $@
    endef
     func = $(call quux, ${adsuffix .o, $(1)})
     echo = $(shell echo $PATH)
  ]]):gsub('    ', ''):gsub('  ', '\t') -- strip indent, convert to tabs
  local tags = {
    lexer.COMMENT, '# Comment.', --
    lexer.VARIABLE_BUILTIN, '.DEFAULT_GOAL', lexer.OPERATOR, ':=', lexer.IDENTIFIER, 'all', --
    lexer.VARIABLE, 'foo', --
    lexer.OPERATOR, '?=', --
    lexer.IDENTIFIER, 'bar', lexer.DEFAULT, '=', lexer.IDENTIFIER, 'baz', --
    lexer.IDENTIFIER, 'all', lexer.OPERATOR, ':', --
    lexer.OPERATOR, '$(', lexer.VARIABLE, 'foo', lexer.OPERATOR, ')', --
    lexer.OPERATOR, '$(', lexer.VARIABLE, 'foo', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ':', lexer.OPERATOR, ';', --
    lexer.FUNCTION_BUILTIN, 'echo', lexer.STRING, "'hi'", --
    lexer.CONSTANT_BUILTIN, '.PHONY', lexer.OPERATOR, ':', lexer.IDENTIFIER, 'docs', --
    lexer.KEYWORD, 'define', lexer.FUNCTION, 'build-cc', lexer.OPERATOR, '=', --
    lexer.OPERATOR, '$(', lexer.VARIABLE_BUILTIN, 'CC', lexer.OPERATOR, ')', --
    lexer.OPERATOR, '${', lexer.VARIABLE_BUILTIN, 'CFLAGS', lexer.OPERATOR, '}', --
    lexer.DEFAULT, '-', lexer.IDENTIFIER, 'c', --
    lexer.OPERATOR, '$', lexer.VARIABLE_BUILTIN, '<', --
    lexer.DEFAULT, '-', lexer.IDENTIFIER, 'o', --
    lexer.OPERATOR, '$', lexer.VARIABLE_BUILTIN, '@', --
    lexer.KEYWORD, 'endef', --
    lexer.FUNCTION, 'func', --
    lexer.OPERATOR, '=', --
    lexer.OPERATOR, '$(', --
    lexer.FUNCTION_BUILTIN, 'call', --
    lexer.FUNCTION, 'quux', --
    lexer.DEFAULT, ',', --
    lexer.OPERATOR, '${', --
    lexer.VARIABLE, 'adsuffix', -- typo should not be tagged as FUNCTION_BUILTIN
    lexer.IDENTIFIER, '.o', --
    lexer.DEFAULT, ',', --
    lexer.OPERATOR, '$(', lexer.VARIABLE, '1', lexer.OPERATOR, ')', --
    lexer.OPERATOR, '}', --
    lexer.OPERATOR, ')', --
    lexer.VARIABLE, 'echo', --
    lexer.OPERATOR, '=', --
    lexer.OPERATOR, '$(', --
    lexer.FUNCTION_BUILTIN, 'shell', --
    lexer.FUNCTION_BUILTIN, 'echo', lexer.OPERATOR, '$', lexer.VARIABLE_BUILTIN, 'PATH', --
    lexer.OPERATOR, ')'
  }
  assert_lex(makefile, code, tags)
end

function test_bash()
  local bash = lexer.load('bash')

  -- Lexing tests.
  local code = [=[
    # Comment.
    foo=bar=baz:$PATH
    echo -n $foo 1>&2
    if [ ! -z "foo" -a 0 -ne 1 ]; then
      quux=$((1 - 2 / 0x3))
    elif [[ -d /foo/bar-baz.quux ]]; then
      foo=$?
    fi
    s=<<-"END"
      foobar
    END
  ]=]
  local tags = {
    lexer.COMMENT, '# Comment.', --
    lexer.VARIABLE, 'foo', --
    lexer.OPERATOR, '=', --
    lexer.IDENTIFIER, 'bar', lexer.DEFAULT, '=', lexer.IDENTIFIER, 'baz', --
    lexer.DEFAULT, ':', --
    lexer.OPERATOR, '$', lexer.VARIABLE_BUILTIN, 'PATH', --
    lexer.FUNCTION_BUILTIN, 'echo', --
    lexer.DEFAULT, '-', lexer.IDENTIFIER, 'n', --
    lexer.OPERATOR, '$', lexer.VARIABLE, 'foo', --
    lexer.NUMBER, '1', lexer.OPERATOR, '>', lexer.OPERATOR, '&', lexer.NUMBER, '2', --
    lexer.KEYWORD, 'if', --
    lexer.OPERATOR, '[', --
    lexer.OPERATOR, '!', --
    lexer.OPERATOR, '-z', lexer.STRING, '"foo"', --
    lexer.OPERATOR, '-a', --
    lexer.NUMBER, '0', lexer.OPERATOR, '-ne', lexer.NUMBER, '1', --
    lexer.OPERATOR, ']', --
    lexer.OPERATOR, ';', lexer.KEYWORD, 'then', --
    lexer.VARIABLE, 'quux', --
    lexer.OPERATOR, '=', --
    lexer.OPERATOR, '$', lexer.OPERATOR, '(', lexer.OPERATOR, '(', --
    lexer.NUMBER, '1', --
    lexer.OPERATOR, '-', --
    lexer.NUMBER, '2', --
    lexer.OPERATOR, '/', --
    lexer.NUMBER, '0x3', --
    lexer.OPERATOR, ')', lexer.OPERATOR, ')', --
    lexer.KEYWORD, 'elif', --
    lexer.OPERATOR, '[', lexer.OPERATOR, '[', --
    lexer.OPERATOR, '-d', --
    lexer.DEFAULT, '/', --
    lexer.IDENTIFIER, 'foo', --
    lexer.DEFAULT, '/', --
    lexer.IDENTIFIER, 'bar', --
    lexer.DEFAULT, '-', --
    lexer.IDENTIFIER, 'baz', --
    lexer.DEFAULT, '.', --
    lexer.IDENTIFIER, 'quux', --
    lexer.OPERATOR, ']', lexer.OPERATOR, ']', lexer.OPERATOR, ';', lexer.KEYWORD, 'then', --
    lexer.VARIABLE, 'foo', --
    lexer.OPERATOR, '=', --
    lexer.OPERATOR, '$', lexer.VARIABLE_BUILTIN, '?', --
    lexer.KEYWORD, 'fi', --
    lexer.VARIABLE, 's', lexer.OPERATOR, '=', lexer.STRING, '<<-"END"\n      foobar\n    END'
  }
  assert_lex(bash, code, tags)

  -- Folding tests.
  code = [[
    function foo() {

    }
    if [ expr ]; then
      case
        *)
        ;;
      esac
    fi
    for x in y; do

    done
  ]]
  local folds = {1, -3, 4, 5, -8, -9, 10, -12}
  assert_fold_points(bash, code, folds)
end

function test_cpp()
  local cpp = lexer.load('cpp')
  local code = [=[
    /*/*Comment.*///
    #include <string>
    #include "header.h"
    #  undef FOO
    [[deprecated]]
    class Foo : public Bar {
      Foo();
      ~Foo();
    private:
      std::string mFoo = u8"foo";
      int mBar = 1;
    };

    Foo::Foo() {
      std::clog << std::abs(strlen(mFoo.c_str()));
      this->bar(1'000 + 0xFF'00 - 0b11'00);
      std::sort(
    }
  ]=]
  local tags = {
    lexer.COMMENT, '/*/*Comment.*/', lexer.COMMENT, '//', --
    lexer.PREPROCESSOR, '#include', lexer.STRING, '<string>', --
    lexer.PREPROCESSOR, '#include', lexer.STRING, '"header.h"', --
    lexer.PREPROCESSOR, '#  undef', lexer.IDENTIFIER, 'FOO', --
    lexer.ATTRIBUTE, '[[deprecated]]', --
    lexer.KEYWORD, 'class', lexer.IDENTIFIER, 'Foo', --
    lexer.OPERATOR, ':', --
    lexer.KEYWORD, 'public', lexer.IDENTIFIER, 'Bar', --
    lexer.OPERATOR, '{', --
    lexer.FUNCTION, 'Foo', lexer.OPERATOR, '(', lexer.OPERATOR, ')', lexer.OPERATOR, ';', --
    lexer.OPERATOR, '~', --
    lexer.FUNCTION, 'Foo', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.KEYWORD, 'private', lexer.OPERATOR, ':', --
    lexer.TYPE .. '.stl', 'std::string', --
    lexer.IDENTIFIER, 'mFoo', --
    lexer.OPERATOR, '=', --
    lexer.STRING, 'u8"foo"', --
    lexer.OPERATOR, ';', --
    lexer.TYPE, 'int', --
    lexer.IDENTIFIER, 'mBar', --
    lexer.OPERATOR, '=', --
    lexer.NUMBER, '1', --
    lexer.OPERATOR, ';', --
    lexer.OPERATOR, '}', lexer.OPERATOR, ';', --
    lexer.IDENTIFIER, 'Foo', --
    lexer.OPERATOR, ':', lexer.OPERATOR, ':', --
    lexer.FUNCTION, 'Foo', --
    lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, '{', --
    lexer.CONSTANT_BUILTIN .. '.stl', 'std::clog', --
    lexer.OPERATOR, '<', lexer.OPERATOR, '<', lexer.FUNCTION_BUILTIN, 'std::abs', --
    lexer.OPERATOR, '(', --
    lexer.FUNCTION_BUILTIN, 'strlen', --
    lexer.OPERATOR, '(', --
    lexer.IDENTIFIER, 'mFoo', --
    lexer.OPERATOR, '.', --
    lexer.FUNCTION_METHOD, 'c_str', lexer.OPERATOR, '(', lexer.OPERATOR, ')', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.KEYWORD, 'this', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '>', --
    lexer.FUNCTION_METHOD, 'bar', --
    lexer.OPERATOR, '(', --
    lexer.NUMBER, "1'000", --
    lexer.OPERATOR, '+', --
    lexer.NUMBER, "0xFF'00", --
    lexer.OPERATOR, '-', --
    lexer.NUMBER, "0b11'00", --
    lexer.OPERATOR, ')', --
    lexer.OPERATOR, ';', --
    lexer.FUNCTION_BUILTIN .. '.stl', 'std::sort', --
    lexer.OPERATOR, '(', --
    lexer.OPERATOR, '}'
  }
  assert_lex(cpp, code, tags)
end

function test_markdown()
  local md = lexer.load('markdown')
  local code = ([[

    # header1
    ## header2

    > block1
    > block2
    block3

    1. l1
    2
    * l2

        code1

    ```
    code2
    ```

    `code3` ``code4`` ``code`5`` `code``6`

        > code7

    ---
    * * *

    [link](target) ![image](target "alt_text") [link] [1]
    http://link text <http://link>
    [1]: link#text

    **strong** *emphasis* \*text\*

    <html>
        </html>

        <a>
  ]]):gsub('\n    ', '\n') -- strip indent
  local tags = {
    lexer.TITLE .. '.h1', '# header1', --
    lexer.TITLE .. '.h2', '## header2', --
    lexer.STRING, '> block1\n> block2\nblock3\n\n', --
    lexer.NUMBER, '1. ', lexer.DEFAULT, 'l', lexer.DEFAULT, '1', --
    lexer.DEFAULT, '2', --
    lexer.NUMBER, '* ', lexer.DEFAULT, 'l', lexer.DEFAULT, '2', --
    lexer.CODE, 'code1\n', --
    lexer.CODE, '```\ncode2\n```\n', --
    lexer.CODE, '`code3`', --
    lexer.CODE, '``code4``', --
    lexer.CODE, '``code`5``', --
    lexer.CODE, '`code``6`', --
    lexer.CODE, '> code7\n', --
    lexer.UNDERLINE .. '.hr', '---\n', --
    lexer.UNDERLINE .. '.hr', '* * *\n', --
    lexer.LINK, '[link](target)', --
    lexer.LINK, '![image](target "alt_text")', --
    lexer.REFERENCE, '[link] [1]', --
    lexer.LINK, 'http://link', --
    lexer.DEFAULT, 't', lexer.DEFAULT, 'e', lexer.DEFAULT, 'x', lexer.DEFAULT, 't', --
    lexer.LINK, '<http://link>', --
    lexer.REFERENCE, '[1]:', lexer.LINK, 'link#text', --
    lexer.BOLD, '**strong**', --
    lexer.ITALIC, '*emphasis*', --
    lexer.DEFAULT, '\\*', --
    lexer.DEFAULT, 't', lexer.DEFAULT, 'e', lexer.DEFAULT, 'x', lexer.DEFAULT, 't', --
    lexer.DEFAULT, '\\*', --
    lexer.TAG .. '.chars', '<', lexer.TAG, 'html', lexer.TAG .. '.chars', '>', --
    lexer.TAG .. '.chars', '</', lexer.TAG, 'html', lexer.TAG .. '.chars', '>', --
    lexer.CODE, '<a>\n'
  }
  assert_lex(md, code, tags)
end

function test_yaml()
  local yaml = lexer.load('yaml')

  local code = ([[
    %YAML directive
    --- # document start
    - item 1
      - item 2
        - - item - 3
        - [1, -2.0e-3, 0x3, 04, two words]
    - &anchor !!str item
    - *anchor
    ... # document end
    key: value
    "key 2": 'value 2'
    key 3: value "3"
    key-4_: {1: true, 2: FALSE, 3: null, 4: .Inf, 5: two words, 6: 2000-01-01T12:00:00.0Z}
    - -key - 5: {one: two, three four: five six}
    ? - item 1
    : - item 2
    - {ok: ok@, @: @}
    literal: |
      line 1

      - line 2
      [line, 3]
      #line 4
      ---

    flow: >
      {line: 5}
      ? - line 6
      @line 7
      %line 8
      ...
    - foo: bar
      baz: |
       quux
    - foobar
  ]]):gsub('    ', '') -- strip indent
  local tags = {
    lexer.PREPROCESSOR, '%YAML directive', --
    lexer.OPERATOR, '---', lexer.COMMENT, '# document start', --
    lexer.OPERATOR, '-', lexer.DEFAULT, 'item 1', --
    lexer.OPERATOR, '-', lexer.DEFAULT, 'item 2', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '-', lexer.DEFAULT, 'item - 3', --
    lexer.OPERATOR, '-', --
    lexer.OPERATOR, '[', --
    lexer.NUMBER, '1', lexer.OPERATOR, ',', --
    lexer.NUMBER, '-2.0e-3', lexer.OPERATOR, ',', --
    lexer.NUMBER, '0x3', lexer.OPERATOR, ',', --
    lexer.NUMBER, '04', lexer.OPERATOR, ',', --
    lexer.DEFAULT, 'two words', --
    lexer.OPERATOR, ']', --
    lexer.OPERATOR, '-', --
    lexer.OPERATOR, '&', lexer.LABEL, 'anchor', lexer.TYPE, '!!str', --
    lexer.DEFAULT, 'i', lexer.DEFAULT, 't', lexer.DEFAULT, 'e', lexer.DEFAULT, 'm', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '*', lexer.LABEL, 'anchor', --
    lexer.OPERATOR, '...', lexer.COMMENT, '# document end', --
    lexer.STRING, 'key', lexer.OPERATOR, ':', lexer.DEFAULT, 'value', --
    lexer.STRING, '"key 2"', lexer.OPERATOR, ':', lexer.STRING, "'value 2'", --
    lexer.STRING, 'key 3', lexer.OPERATOR, ':', lexer.DEFAULT, 'value "3"', --
    lexer.STRING, 'key-4_', --
    lexer.OPERATOR, ':', --
    lexer.OPERATOR, '{', --
    lexer.STRING, '1', lexer.OPERATOR, ':', lexer.CONSTANT_BUILTIN, 'true', lexer.OPERATOR, ',', --
    lexer.STRING, '2', lexer.OPERATOR, ':', lexer.CONSTANT_BUILTIN, 'FALSE', lexer.OPERATOR, ',', --
    lexer.STRING, '3', lexer.OPERATOR, ':', lexer.CONSTANT_BUILTIN, 'null', lexer.OPERATOR, ',', --
    lexer.STRING, '4', lexer.OPERATOR, ':', lexer.NUMBER, '.Inf', lexer.OPERATOR, ',', --
    lexer.STRING, '5', lexer.OPERATOR, ':', lexer.DEFAULT, 'two words', lexer.OPERATOR, ',', --
    lexer.STRING, '6', lexer.OPERATOR, ':', lexer.NUMBER .. '.timestamp', '2000-01-01T12:00:00.0Z', --
    lexer.OPERATOR, '}', --
    lexer.OPERATOR, '-', --
    lexer.STRING, '-key - 5', --
    lexer.OPERATOR, ':', --
    lexer.OPERATOR, '{', --
    lexer.STRING, 'one', lexer.OPERATOR, ':', lexer.DEFAULT, 'two', lexer.OPERATOR, ',', --
    lexer.STRING, 'three four', lexer.OPERATOR, ':', lexer.DEFAULT, 'five six', --
    lexer.OPERATOR, '}', --
    lexer.OPERATOR, '?', lexer.OPERATOR, '-', lexer.DEFAULT, 'item 1', --
    lexer.OPERATOR, ':', lexer.OPERATOR, '-', lexer.DEFAULT, 'item 2', --
    lexer.OPERATOR, '-', lexer.OPERATOR, '{', lexer.STRING, 'ok', lexer.OPERATOR, ':',
    lexer.DEFAULT, 'ok@', lexer.OPERATOR, ',', --
    lexer.ERROR, '@', lexer.OPERATOR, ':', lexer.ERROR, '@', --
    lexer.OPERATOR, '}', --
    lexer.STRING, 'literal', --
    lexer.OPERATOR, ':', --
    lexer.DEFAULT, '|\n  line 1\n\n  - line 2\n  [line, 3]\n  #line 4\n  ---\n', --
    lexer.STRING, 'flow', --
    lexer.OPERATOR, ':', --
    lexer.DEFAULT, '>\n  {line: 5}\n  ? - line 6\n  @line 7\n  %line 8\n  ...', --
    lexer.OPERATOR, '-', lexer.STRING, 'foo', lexer.OPERATOR, ':', lexer.DEFAULT, 'bar', --
    lexer.STRING, 'baz', lexer.OPERATOR, ':', lexer.DEFAULT, '|\n   quux', --
    lexer.OPERATOR, '-', lexer.DEFAULT, 'foobar' --
  }
  assert_lex(yaml, code, tags)

  -- Simulate inserting a newline after |.
  code = ([[
    - foo: bar
      baz: |

       quux
    - foobar
  ]]):gsub('    ', '') -- strip indent
  tags = {
    lexer.DEFAULT, '|\n\n   quux', --
    lexer.OPERATOR, '-', lexer.DEFAULT, 'foobar'
  }
  assert_lex(yaml, code:match('(|.+)$'), tags, lexer.DEFAULT)
end

function test_legacy()
  local lex = lexer.new('test')
  local ws = lexer.token(lexer.WHITESPACE, lexer.space^1)
  lex:add_rule('whitespace', ws) -- should call lex:modify_rule()
  assert(#lex._rules == 1 + lexer.num_user_word_lists)
  assert(lex._rules['whitespace'] == ws)
  lex:add_rule('keyword', lexer.token(lexer.KEYWORD, lexer.word_match('foo bar baz')))
  lex:add_rule('number', lexer.token(lexer.NUMBER, lexer.number))
  lex:add_rule('preproc', lexer.token(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#'))))
  lex:add_style('whatever', lexer.styles.keyword .. {fore = lexer.colors.red, italic = true})
  local code = "foo 1 bar 2 baz 3\n#quux"
  local tags = {
    lexer.KEYWORD, 'foo', --
    lexer.NUMBER, '1', --
    lexer.KEYWORD, 'bar', --
    lexer.NUMBER, '2', --
    lexer.KEYWORD, 'baz', --
    lexer.NUMBER, '3', --
    lexer.PREPROCESSOR, '#quux'
  }
  assert_lex(lex, code, tags)
end

function test_lua51()
  local p = io.popen(
    [[cd lexers && lua5.1 -e 'lexer=require"lexer"' -e 'print(unpack(lexer.load("lua"):lex("_G")))']])
  local output = p:read('a')
  p:close()
  assert(output == lexer.CONSTANT_BUILTIN .. '\t3\n')
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
