-- Copyright 2017-2023 Mitchell. See LICENSE.
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
    'default', 'line.number', 'brace.light', 'brace.bad', 'control.char', 'indent.guide',
    'call.tip', 'fold.display.text'
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
-- @usage assert_lex(lua, "print('hi')", {FUNCTION_BUILTIN, 'print', OPERATOR, '(', STRING, "'hi'",
--   OPERATOR, ')'}})
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
  assert(not lexer.to_eol('f'):match(code))
  assert(lexer.to_eol():match(code) == 6)
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

local DEFAULT = lexer.DEFAULT
local COMMENT = lexer.COMMENT
local STRING = lexer.STRING
local NUMBER = lexer.NUMBER
local KEYWORD = lexer.KEYWORD
local IDENTIFIER = lexer.IDENTIFIER
local OPERATOR = lexer.OPERATOR
local ERROR = lexer.ERROR
local PREPROCESSOR = lexer.PREPROCESSOR
local VARIABLE = lexer.VARIABLE
local FUNCTION = lexer.FUNCTION
local CLASS = lexer.CLASS
local TYPE = lexer.TYPE
local LABEL = lexer.LABEL
local REGEX = lexer.REGEX
local FUNCTION_BUILTIN = lexer.FUNCTION_BUILTIN
local CONSTANT_BUILTIN = lexer.CONSTANT_BUILTIN
local FUNCTION_METHOD = lexer.FUNCTION_METHOD
local TAG = lexer.TAG
local ATTRIBUTE = lexer.ATTRIBUTE
local VARIABLE_BUILTIN = lexer.VARIABLE_BUILTIN
local HEADING = lexer.HEADING
local BOLD = lexer.BOLD
local ITALIC = lexer.ITALIC
local UNDERLINE = lexer.UNDERLINE
local CODE = lexer.CODE
local LINK = lexer.LINK
local REFERENCE = lexer.REFERENCE
local ANNOTATION = lexer.ANNOTATION
local LIST = lexer.LIST

-- Tests a basic lexer with a few simple rules and no custom styles.
function test_basics()
  local lex = lexer.new('test')
  assert_default_tags(lex)
  lex:add_rule('keyword', lex:tag(KEYWORD, word_match('foo bar baz')))
  lex:add_rule('string', lex:tag(STRING, lexer.range('"')))
  lex:add_rule('number', lex:tag(NUMBER, lexer.integer))
  local code = [[foo bar baz "foo bar baz" 123]]
  local tags = {
    KEYWORD, 'foo', --
    KEYWORD, 'bar', --
    KEYWORD, 'baz', --
    STRING, '"foo bar baz"', --
    NUMBER, '123'
  }
  assert_lex(lex, code, tags)
end

-- Tests that lexer rules are added in an ordered sequence and that modifying rules in place
-- works as expected.
function test_rule_order()
  local lex = lexer.new('test')
  lex:add_rule('identifier', lex:tag(IDENTIFIER, lexer.word))
  lex:add_rule('keyword', lex:tag(KEYWORD, lpeg.P('foo')))
  local code = [[foo bar]]
  local tags = {IDENTIFIER, 'foo', IDENTIFIER, 'bar'}
  assert_lex(lex, code, tags)

  -- Modify the identifier rule to not catch keywords.
  lex:modify_rule('identifier', -lpeg.P('foo') * lex:tag(IDENTIFIER, lexer.word))
  tags = {KEYWORD, 'foo', IDENTIFIER, 'bar'}
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
  lex:add_rule('keyword', lex:tag(KEYWORD, lex:word_match(KEYWORD)))
  lex:add_rule('identifier', lex:tag(IDENTIFIER, lexer.word))
  lex:add_rule('operator', lex:tag(OPERATOR, '.'))
  local code = [[foo bar.baz quux]]
  local tags = {
    IDENTIFIER, 'foo', --
    IDENTIFIER, 'bar', --
    OPERATOR, '.', --
    IDENTIFIER, 'baz', --
    IDENTIFIER, 'quux'
  }
  assert_lex(lex, code, tags)

  lex:set_word_list(KEYWORD, 'foo quux')
  tags[1 * 2 - 1], tags[1 * 2] = KEYWORD, 'foo'
  tags[5 * 2 - 1], tags[5 * 2] = KEYWORD, 'quux'
  assert_lex(lex, code, tags)

  lex:set_word_list(KEYWORD, 'bar', true) -- append
  tags[2 * 2 - 1], tags[2 * 2] = KEYWORD, 'bar'
  assert_lex(lex, code, tags)

  lex:set_word_list(KEYWORD, {'bar.baz'})
  tags = {IDENTIFIER, 'foo', KEYWORD, 'bar.baz', IDENTIFIER, 'quux'}
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
    'child', '1', DEFAULT, ',', 'child', '2', DEFAULT, ',', 'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(parent, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  tags = {
    'child', '2', DEFAULT, ',', 'child', '3', 'transition', ']', --
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
    'child', '1', DEFAULT, ',', 'child', '2', DEFAULT, ',', 'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(child, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[2, 3] bar]]
  tags = {
    'child', '2', DEFAULT, ',', 'child', '3', 'transition', ']', --
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
    'child', '1', DEFAULT, ',', 'child', '2', DEFAULT, ',', 'child', '3', --
    'transition', ']', --
    'parent', 'bar'
  }
  assert_lex(proxy, code, tags)

  -- Lex some child -> parent code, starting from within the child.
  code = [[ 2, 3] bar]]
  tags = {
    'child', '2', DEFAULT, ',', 'child', '3', 'transition', ']', --
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
  lex:add_rule('keyword', lex:tag(KEYWORD, word_match('foo bar baz')))

  -- Verify inherited rules are used.
  local sublexer = lexer.new('test2', {inherit = lex})
  local code = [[foo bar baz]]
  local tags = {KEYWORD, 'foo', KEYWORD, 'bar', KEYWORD, 'baz'}
  assert_lex(sublexer, code, tags)

  -- Verify subsequently added rules are also used.
  sublexer:add_rule('keyword2', sublexer:tag(KEYWORD, lpeg.P('quux')))
  code = [[foo bar baz quux]]
  tags = {KEYWORD, 'foo', KEYWORD, 'bar', KEYWORD, 'baz', KEYWORD, 'quux'}
  assert_lex(sublexer, code, tags)
end

-- Tests that fold words are folded properly, even if fold words are substrings of others
-- (e.g. "if" and "endif").
function test_fold_words()
  local lex = lexer.new('test')
  lex:add_rule('keyword', lex:tag(KEYWORD, word_match('if endif')))
  lex:add_fold_point(KEYWORD, 'if', 'endif')

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

function test_names()
  lexer.property['scintillua.lexers'] = ''
  local names = lexer.names()
  assert(#names > 0)
  local lua_found = false
  for _, name in ipairs(names) do
    assert(name ~= 'lexer')
    if name == 'lua' then lua_found = true end
  end
  assert(lua_found)
  local names2 = lexer.names('lexers')
  assert(#names == #names2)
  lexer.property['scintillua.lexers'] = 'lexers'
  local names3 = lexer.names()
  assert(#names == #names3)
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
    STRING .. '.longstring', --
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
    COMMENT, '--[[ Comment. ]]', COMMENT, '--', --
    LABEL, '::begin::', --
    KEYWORD, 'local', IDENTIFIER, 'a', ATTRIBUTE, '<const>', --
    OPERATOR, '=', --
    NUMBER, '-1', OPERATOR, '+', NUMBER, '2.0e3', OPERATOR, '-', NUMBER, '0x40', --
    KEYWORD, 'local', IDENTIFIER, 'b', --
    OPERATOR, '=', --
    STRING, '"two"', --
    OPERATOR, '..', --
    STRING .. '.longstring', '[[three]]', --
    OPERATOR, '..', --
    STRING, "'four\\''", --
    IDENTIFIER, 'c', --
    OPERATOR, '=', --
    OPERATOR, '{', --
    CONSTANT_BUILTIN, '_G', OPERATOR, '.', IDENTIFIER, 'print', --
    OPERATOR, ',', --
    IDENTIFIER, 'type', --
    OPERATOR, '=', --
    FUNCTION, 'foo', OPERATOR, '{', CONSTANT_BUILTIN, 'math.pi', OPERATOR, '}', OPERATOR, '}', --
    FUNCTION_BUILTIN, 'print', --
    OPERATOR, '(', --
    FUNCTION_BUILTIN, 'string.upper', STRING, "'a'", --
    OPERATOR, ',', --
    IDENTIFIER, 'b', OPERATOR, ':', FUNCTION_METHOD, 'upper', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, ')'
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

  -- Test overriding keywords.
  lua:set_word_list(KEYWORD, '')
  assert_lex(lua, 'if', {IDENTIFIER, 'if'})

  -- Test adding to built-in functions.
  lua:set_word_list(FUNCTION_BUILTIN, 'module', true) -- from Lua 5.1
  assert_lex(lua, 'dofile(', {FUNCTION_BUILTIN, 'dofile', OPERATOR, '('})
  assert_lex(lua, 'module(', {FUNCTION_BUILTIN, 'module', OPERATOR, '('})
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
    COMMENT, '/* Comment. */', --
    PREPROCESSOR, '#include', STRING, '<stdio.h>', --
    PREPROCESSOR, '#include', STRING, '"lua.h"', --
    PREPROCESSOR, '#  define', IDENTIFIER, 'INT_MAX_', NUMBER, '1', --
    TYPE, 'int', FUNCTION, 'main', --
    OPERATOR, '(', --
    TYPE, 'int', IDENTIFIER, 'argc', --
    OPERATOR, ',', --
    TYPE, 'char', OPERATOR, '*', OPERATOR, '*', IDENTIFIER, 'argv', --
    OPERATOR, ')', --
    OPERATOR, '{', --
    LABEL, 'begin:', --
    KEYWORD, 'if', OPERATOR, '(', CONSTANT_BUILTIN, 'NULL', OPERATOR, ')', COMMENT, '// comment', --
    FUNCTION_BUILTIN, 'printf', --
    OPERATOR, '(', --
    STRING, '"%ld %f %s %i"', --
    OPERATOR, ',', --
    NUMBER, '1l', --
    OPERATOR, ',', --
    NUMBER, '1.0e-1f', --
    OPERATOR, ',', --
    STRING, 'L"foo"', --
    OPERATOR, ',', --
    CONSTANT_BUILTIN, 'INT_MAX', --
    OPERATOR, ')', --
    OPERATOR, ';', --
    IDENTIFIER, 'foo', OPERATOR, '.', IDENTIFIER, 'free', --
    OPERATOR, ',', --
    IDENTIFIER, 'foo', --
    OPERATOR, '-', OPERATOR, '>', --
    FUNCTION_METHOD, 'free', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, ',', --
    FUNCTION_BUILTIN, 'free', OPERATOR, '(', IDENTIFIER, 'foo', OPERATOR, ')', --
    OPERATOR, ';', --
    KEYWORD, 'return', --
    NUMBER, '0x0', --
    OPERATOR, '?', --
    IDENTIFIER, 'argc', -- should not be a label
    OPERATOR, ':', --
    NUMBER, '0', --
    OPERATOR, ';', --
    OPERATOR, '}'
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
    TAG .. '.doctype', TAG .. '.unknown', ATTRIBUTE .. '.unknown', --
    'whitespace.html', -- HTML
    'property', 'whitespace.css', -- CSS
    'whitespace.javascript', -- JS
    'whitespace.coffeescript' -- CoffeeScript
  }
  assert_extra_tags(html, tags)
  assert_children(html, {'css', 'css.style', 'javascript', 'coffeescript'})

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
            color: red;
            border: 1.5px solid #0000FF;
            background: url("/images/image.jpg");
          }
          table.class {}
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
      <div style="float: right">
    </html>
  ]]
  local tag_chars = TAG .. '.chars'
  tags = {
    TAG .. '.doctype', '<!DOCTYPE html>', --
    COMMENT, '<!-- Comment. -->', --
    tag_chars, '<', TAG, 'html', tag_chars, '>', --
    tag_chars, '<', TAG, 'HEAD', tag_chars, '>', --
    tag_chars, '<', TAG, 'style', --
    ATTRIBUTE, 'type', OPERATOR, '=', STRING, '"text/css"', --
    tag_chars, '>', --
    PREPROCESSOR, '@charset', STRING, '"utf8"', --
    COMMENT, '/* Another comment. */', --
    TAG, 'h1', 'pseudoclass', ':hover', --
    OPERATOR, ',', --
    TAG, 'h2', 'pseudoelement', '::first-line', --
    OPERATOR, '{', --
    'property', 'color', OPERATOR, ':', CONSTANT_BUILTIN, 'red', OPERATOR, ';', --
    'property', 'border', --
    OPERATOR, ':', --
    NUMBER, '1.5px', CONSTANT_BUILTIN, 'solid', NUMBER, '#0000FF', --
    OPERATOR, ';', --
    'property', 'background', --
    OPERATOR, ':', --
    FUNCTION_BUILTIN, 'url', OPERATOR, '(', STRING, '"/images/image.jpg"', OPERATOR, ')', --
    OPERATOR, ';', --
    OPERATOR, '}', --
    TAG, 'table', OPERATOR, '.', IDENTIFIER, 'class', OPERATOR, '{', OPERATOR, '}', --
    tag_chars, '</', TAG, 'style', tag_chars, '>', --
    tag_chars, '<', TAG, 'script', --
    ATTRIBUTE, 'type', OPERATOR, '=', STRING, '"text/javascript"', --
    tag_chars, '>', --
    COMMENT, '/* A third comment. */', --
    KEYWORD, 'var', IDENTIFIER, 'a', --
    OPERATOR, '=', --
    NUMBER, '1', OPERATOR, '+', NUMBER, '2.0e3', OPERATOR, '-', NUMBER, '0x40', --
    OPERATOR, ';', --
    KEYWORD, 'var', IDENTIFIER, 'b', --
    OPERATOR, '=', --
    STRING, '"two"', OPERATOR, '+', STRING, '`three`', --
    OPERATOR, ';', --
    KEYWORD, 'var', IDENTIFIER, 'c', OPERATOR, '=', REGEX, '/pattern/i', OPERATOR, ';', --
    FUNCTION, 'foo', --
    OPERATOR, '(', --
    FUNCTION_BUILTIN, 'eval', OPERATOR, '(', CONSTANT_BUILTIN, 'arguments', OPERATOR, ')', --
    OPERATOR, ',', --
    IDENTIFIER, 'bar', OPERATOR, '.', FUNCTION_METHOD, 'baz', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, ',', --
    TYPE, 'Object', --
    OPERATOR, ')', --
    OPERATOR, ';', --
    tag_chars, '</', TAG, 'script', tag_chars, '>', --
    tag_chars, '</', TAG, 'HEAD', tag_chars, '>', --
    tag_chars, '<', TAG .. '.unknown', 'bod', --
    ATTRIBUTE .. '.unknown', 'clss', OPERATOR, '=', STRING, '"unknown"', --
    tag_chars, '>', --
    tag_chars, '<', TAG .. '.single', 'hr', --
    ATTRIBUTE, 'tabindex', OPERATOR, '=', NUMBER, '1', --
    tag_chars, '/>', --
    CONSTANT_BUILTIN .. '.entity', '&copy;', --
    tag_chars, '<', TAG, 'div', --
    ATTRIBUTE, 'style', OPERATOR, '=', STRING, '"', --
    'property', 'float', OPERATOR, ':', CONSTANT_BUILTIN, 'right', --
    STRING, '"', tag_chars, '>', --
    tag_chars, '</', TAG, 'html', tag_chars, '>'
  }
  assert_lex(html, code, tags)

  -- Folding tests.
  local symbols = {'<', '<!--', '-->', '{', '}', '/*', '*/'}
  for i = 1, #symbols do assert(html._fold_points._symbols[symbols[i]]) end
  assert(html._fold_points[TAG .. '.chars']['<'])
  assert(html._fold_points[COMMENT]['<!--'])
  assert(html._fold_points[COMMENT]['-->'])
  assert(html._fold_points[OPERATOR]['{'])
  assert(html._fold_points[OPERATOR]['}'])
  assert(html._fold_points[COMMENT]['/*'])
  assert(html._fold_points[COMMENT]['*/'])
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
  assert_extra_tags(php, {'whitespace.php'})

  -- Lexing tests
  -- Starting in HTML.
  local code = [[<h1><?php echo "hi" . PHP_OS . foo() . bar->baz(); ?></h1>]]
  local tag_chars = TAG .. '.chars'
  local tags = {
    tag_chars, '<', TAG, 'h1', tag_chars, '>', --
    PREPROCESSOR, '<?php ', --
    KEYWORD, 'echo', --
    STRING, '"hi"', --
    OPERATOR, '.', --
    CONSTANT_BUILTIN, 'PHP_OS', --
    OPERATOR, '.', --
    FUNCTION, 'foo', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, '.', --
    IDENTIFIER, 'bar', --
    OPERATOR, '-', OPERATOR, '>', --
    FUNCTION_METHOD, 'baz', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, ';', --
    PREPROCESSOR, '?>', --
    tag_chars, '</', TAG, 'h1', tag_chars, '>'
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
  tags = {KEYWORD, 'echo', STRING, '"hi"', OPERATOR, ';'}
  assert_lex(php, code, tags, initial_style)

  -- Folding tests.
  local symbols = {'<?', '?>', '/*', '*/', '{', '}', '(', ')'}
  for i = 1, #symbols do assert(php._fold_points._symbols[symbols[i]]) end
  assert(php._fold_points[PREPROCESSOR]['<?'])
  assert(php._fold_points[PREPROCESSOR]['?>'])
  assert(php._fold_points[COMMENT]['/*'])
  assert(php._fold_points[COMMENT]['*/'])
  assert(php._fold_points[OPERATOR]['{'])
  assert(php._fold_points[OPERATOR]['}'])
  assert(php._fold_points[OPERATOR]['('])
  assert(php._fold_points[OPERATOR][')'])
end

-- Tests the Ruby lexer.
function test_ruby()
  local ruby = lexer.load('ruby')

  -- Lexing tests.
  local code = [[
    # Comment.
    require "foo"
    $a = 1 + 2.0e3 - 0x4_0 if true
    b = "two" + %q[three] + <<-FOUR
      four
    FOUR
    puts :c, foo.puts
  ]]
  local tags = {
    COMMENT, '# Comment.', --
    FUNCTION_BUILTIN, 'require', STRING, '"foo"', --
    VARIABLE, '$a', --
    OPERATOR, '=', --
    NUMBER, '1', OPERATOR, '+', NUMBER, '2.0e3', OPERATOR, '-', NUMBER, '0x4_0', --
    KEYWORD, 'if', KEYWORD, 'true', --
    IDENTIFIER, 'b', --
    OPERATOR, '=', --
    STRING, '"two"', --
    OPERATOR, '+', --
    STRING, '%q[three]', --
    OPERATOR, '+', --
    STRING, '<<-FOUR\n      four\n    FOUR', --
    FUNCTION_BUILTIN, 'puts', STRING .. '.symbol', ':c', --
    OPERATOR, ',', --
    IDENTIFIER, 'foo', OPERATOR, '.', IDENTIFIER, 'puts'
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
      assert(ruby._fold_points[KEYWORD][k] == v)
    else
      assert(type(ruby._fold_points[KEYWORD][k]) == 'function')
    end
  end
  local fold_operators = {'(', ')', '[', ']', '{', '}'}
  for i = 1, #fold_operators do
    assert(ruby._fold_points._symbols[fold_operators[i]])
    assert(ruby._fold_points[OPERATOR][fold_operators[i]])
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
    KEYWORD, 'class', IDENTIFIER, 'Foo', --
    OPERATOR, '<', --
    IDENTIFIER, 'ActiveRecord', OPERATOR, ':', OPERATOR, ':', IDENTIFIER, 'Base', --
    IDENTIFIER, 'has_one', -- function.builtin in rails
    STRING .. '.symbol', ':bar', --
    KEYWORD, 'end'
  }
  assert_lex(ruby, code, ruby_tags)

  local rails_tags = {
    KEYWORD, 'class', IDENTIFIER, 'Foo', --
    OPERATOR, '<', --
    IDENTIFIER, 'ActiveRecord', OPERATOR, ':', OPERATOR, ':', IDENTIFIER, 'Base', --
    FUNCTION_BUILTIN, 'has_one', STRING .. '.symbol', ':bar', --
    KEYWORD, 'end'
  }
  assert_lex(rails, code, rails_tags)
end

-- Tests the RHTML lexer, which is a proxy for HTML and Rails.
function test_rhtml()
  local rhtml = lexer.load('rhtml')

  -- Lexing tests.
  -- Start in HTML.
  local code = [[<h1><% puts "hi" + link_to "foo" @foo %></h1>]]
  local tag_chars = TAG .. '.chars'
  local rhtml_tags = {
    tag_chars, '<', TAG, 'h1', tag_chars, '>', --
    lexer.PREPROCESSOR, '<%', --
    FUNCTION_BUILTIN, 'puts', STRING, '"hi"', --
    OPERATOR, '+', --
    FUNCTION_BUILTIN, 'link_to', STRING, '"foo"', VARIABLE, '@foo', --
    lexer.PREPROCESSOR, '%>', --
    tag_chars, '</', TAG, 'h1', tag_chars, '>'
  }
  local initial_style = rhtml._TAGS['whitespace.html']
  assert_lex(rhtml, code, rhtml_tags, initial_style)
  -- Start in Ruby.
  code = [[puts "hi" + link_to "foo" @foo]]
  rhtml_tags = {
    FUNCTION_BUILTIN, 'puts', STRING, '"hi"', --
    OPERATOR, '+', --
    FUNCTION_BUILTIN, 'link_to', STRING, '"foo"', VARIABLE, '@foo'
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

-- Tests the Makefile lexer with bash/shell embedded two different ways.
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
    COMMENT, '# Comment.', --
    VARIABLE_BUILTIN, '.DEFAULT_GOAL', OPERATOR, ':=', IDENTIFIER, 'all', --
    VARIABLE, 'foo', OPERATOR, '?=', IDENTIFIER, 'bar', DEFAULT, '=', IDENTIFIER, 'baz', --
    IDENTIFIER, 'all', OPERATOR, ':', OPERATOR, '$(', VARIABLE, 'foo', OPERATOR, ')', --
    OPERATOR, '$(', VARIABLE, 'foo', OPERATOR, ')', --
    OPERATOR, ':', OPERATOR, ';', --
    FUNCTION_BUILTIN, 'echo', STRING, "'hi'", --
    CONSTANT_BUILTIN, '.PHONY', OPERATOR, ':', IDENTIFIER, 'docs', --
    KEYWORD, 'define', FUNCTION, 'build-cc', OPERATOR, '=', --
    OPERATOR, '$(', VARIABLE_BUILTIN, 'CC', OPERATOR, ')', --
    OPERATOR, '${', VARIABLE_BUILTIN, 'CFLAGS', OPERATOR, '}', --
    DEFAULT, '-c', --
    OPERATOR, '$', VARIABLE_BUILTIN, '<', --
    DEFAULT, '-o', --
    OPERATOR, '$', VARIABLE_BUILTIN, '@', --
    KEYWORD, 'endef', --
    FUNCTION, 'func', --
    OPERATOR, '=', --
    OPERATOR, '$(', FUNCTION_BUILTIN, 'call', --
    FUNCTION, 'quux', --
    DEFAULT, ',', --
    OPERATOR, '${', --
    VARIABLE, 'adsuffix', -- typo should not be tagged as FUNCTION_BUILTIN
    IDENTIFIER, '.o', --
    DEFAULT, ',', --
    OPERATOR, '$(', VARIABLE, '1', OPERATOR, ')', --
    OPERATOR, '}', --
    OPERATOR, ')', --
    VARIABLE, 'echo', --
    OPERATOR, '=', --
    OPERATOR, '$(', FUNCTION_BUILTIN, 'shell', --
    FUNCTION_BUILTIN, 'echo', OPERATOR, '$', VARIABLE_BUILTIN, 'PATH', --
    OPERATOR, ')'
  }
  assert_lex(makefile, code, tags)
end

-- Tests the Bash lexer, where some operators are recognized only in certain contexts.
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
    COMMENT, '# Comment.', --
    VARIABLE, 'foo', --
    OPERATOR, '=', --
    IDENTIFIER, 'bar', DEFAULT, '=', IDENTIFIER, 'baz', --
    DEFAULT, ':', --
    OPERATOR, '$', VARIABLE_BUILTIN, 'PATH', --
    FUNCTION_BUILTIN, 'echo', --
    DEFAULT, '-n', --
    OPERATOR, '$', VARIABLE, 'foo', --
    NUMBER, '1', OPERATOR, '>', OPERATOR, '&', NUMBER, '2', --
    KEYWORD, 'if', --
    OPERATOR, '[', --
    OPERATOR, '!', DEFAULT, '-z', STRING, '"foo"', --
    DEFAULT, '-a', --
    NUMBER, '0', DEFAULT, '-ne', NUMBER, '1', --
    OPERATOR, ']', --
    OPERATOR, ';', KEYWORD, 'then', --
    VARIABLE, 'quux', --
    OPERATOR, '=', --
    OPERATOR, '$', OPERATOR, '(', OPERATOR, '(', --
    NUMBER, '1', DEFAULT, '-', NUMBER, '2', DEFAULT, '/', NUMBER, '0x3', --
    OPERATOR, ')', OPERATOR, ')', --
    KEYWORD, 'elif', --
    OPERATOR, '[', OPERATOR, '[', --
    DEFAULT, '-d', --
    DEFAULT, '/', --
    IDENTIFIER, 'foo', --
    DEFAULT, '/', --
    IDENTIFIER, 'bar', DEFAULT, '-baz', DEFAULT, '.', IDENTIFIER, 'quux', --
    OPERATOR, ']', OPERATOR, ']', OPERATOR, ';', KEYWORD, 'then', --
    VARIABLE, 'foo', OPERATOR, '=', OPERATOR, '$', VARIABLE_BUILTIN, '?', --
    KEYWORD, 'fi', --
    VARIABLE, 's', OPERATOR, '=', STRING, '<<-"END"\n      foobar\n    END'
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

-- Tests the C++ lexer.
function test_cpp()
  local cpp = lexer.load('cpp')
  local code = [=[
    /*/*Comment.*///
    #include <string>
    #include "header.h"
    #  undef FOO
    [[deprecated]]
    class Foo : public Bar
    {
      Foo();
      ~Foo();
    private:
      std::string mFoo = u8"foo";
      int mBar = 1;
    };

    Foo::Foo()
    {
      std::clog << std::abs(strlen(mFoo.c_str()));
      this->bar(1'000 + 0xFF'00 - 0b11'00);
      std::sort(
    }
  ]=]
  local tags = {
    COMMENT, '/*/*Comment.*/', COMMENT, '//', --
    PREPROCESSOR, '#include', STRING, '<string>', --
    PREPROCESSOR, '#include', STRING, '"header.h"', --
    PREPROCESSOR, '#  undef', IDENTIFIER, 'FOO', --
    ATTRIBUTE, '[[deprecated]]', --
    KEYWORD, 'class', IDENTIFIER, 'Foo', OPERATOR, ':', KEYWORD, 'public', IDENTIFIER, 'Bar', --
    OPERATOR, '{', --
    FUNCTION, 'Foo', OPERATOR, '(', OPERATOR, ')', OPERATOR, ';', --
    OPERATOR, '~', FUNCTION, 'Foo', OPERATOR, '(', OPERATOR, ')', OPERATOR, ';', --
    KEYWORD, 'private', OPERATOR, ':', --
    TYPE .. '.stl', 'std::string', --
    IDENTIFIER, 'mFoo', --
    OPERATOR, '=', --
    STRING, 'u8"foo"', --
    OPERATOR, ';', --
    TYPE, 'int', IDENTIFIER, 'mBar', OPERATOR, '=', NUMBER, '1', OPERATOR, ';', --
    OPERATOR, '}', OPERATOR, ';', --
    IDENTIFIER, 'Foo', OPERATOR, ':', OPERATOR, ':', FUNCTION, 'Foo', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, '{', --
    CONSTANT_BUILTIN .. '.stl', 'std::clog', --
    OPERATOR, '<', OPERATOR, '<', --
    FUNCTION_BUILTIN, 'std::abs', --
    OPERATOR, '(', --
    FUNCTION_BUILTIN, 'strlen', --
    OPERATOR, '(', --
    IDENTIFIER, 'mFoo', OPERATOR, '.', FUNCTION_METHOD, 'c_str', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, ')', --
    OPERATOR, ')', --
    OPERATOR, ';', --
    KEYWORD, 'this', --
    OPERATOR, '-', OPERATOR, '>', --
    FUNCTION_METHOD, 'bar', --
    OPERATOR, '(', --
    NUMBER, "1'000", OPERATOR, '+', NUMBER, "0xFF'00", OPERATOR, '-', NUMBER, "0b11'00", --
    OPERATOR, ')', --
    OPERATOR, ';', --
    FUNCTION_BUILTIN .. '.stl', 'std::sort', OPERATOR, '(', --
    OPERATOR, '}'
  }
  assert_lex(cpp, code, tags)
end

-- Tests the Markdown lexer with embedded HTML.
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
    HEADING .. '.h1', '# header1', --
    HEADING .. '.h2', '## header2', --
    STRING, '> block1\n> block2\nblock3\n\n', --
    LIST, '1. ', DEFAULT, 'l', DEFAULT, '1', --
    DEFAULT, '2', --
    LIST, '* ', DEFAULT, 'l', DEFAULT, '2', --
    CODE, 'code1', --
    CODE, '```\ncode2\n```\n', --
    CODE, '`code3`', CODE, '``code4``', CODE, '``code`5``', CODE, '`code``6`', --
    CODE, '> code7', --
    'hr', '---\n', --
    'hr', '* * *\n', --
    LINK, '[link](target)', LINK, '![image](target "alt_text")', REFERENCE, '[link] [1]', --
    LINK, 'http://link', --
    DEFAULT, 't', DEFAULT, 'e', DEFAULT, 'x', DEFAULT, 't', --
    LINK, '<http://link>', --
    REFERENCE, '[1]:', LINK, 'link#text', --
    BOLD, '**strong**', --
    ITALIC, '*emphasis*', --
    DEFAULT, '\\*', DEFAULT, 't', DEFAULT, 'e', DEFAULT, 'x', DEFAULT, 't', DEFAULT, '\\*', --
    TAG .. '.chars', '<', TAG, 'html', TAG .. '.chars', '>', --
    TAG .. '.chars', '</', TAG, 'html', TAG .. '.chars', '>', --
    CODE, '<a>'
  }
  assert_lex(md, code, tags)
end

-- Tests the YAML lexer.
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
    PREPROCESSOR, '%YAML directive', --
    OPERATOR, '---', COMMENT, '# document start', --
    OPERATOR, '-', DEFAULT, 'item 1', --
    OPERATOR, '-', DEFAULT, 'item 2', --
    OPERATOR, '-', OPERATOR, '-', DEFAULT, 'item - 3', --
    OPERATOR, '-', --
    OPERATOR, '[', --
    NUMBER, '1', OPERATOR, ',', --
    NUMBER, '-2.0e-3', OPERATOR, ',', --
    NUMBER, '0x3', OPERATOR, ',', --
    NUMBER, '04', OPERATOR, ',', --
    DEFAULT, 'two words', --
    OPERATOR, ']', --
    OPERATOR, '-', --
    OPERATOR, '&', LABEL, 'anchor', TYPE, '!!str', --
    DEFAULT, 'i', DEFAULT, 't', DEFAULT, 'e', DEFAULT, 'm', --
    OPERATOR, '-', OPERATOR, '*', LABEL, 'anchor', --
    OPERATOR, '...', COMMENT, '# document end', --
    STRING, 'key', OPERATOR, ':', DEFAULT, 'value', --
    STRING, '"key 2"', OPERATOR, ':', STRING, "'value 2'", --
    STRING, 'key 3', OPERATOR, ':', DEFAULT, 'value "3"', --
    STRING, 'key-4_', OPERATOR, ':', OPERATOR, '{', --
    STRING, '1', OPERATOR, ':', CONSTANT_BUILTIN, 'true', OPERATOR, ',', --
    STRING, '2', OPERATOR, ':', CONSTANT_BUILTIN, 'FALSE', OPERATOR, ',', --
    STRING, '3', OPERATOR, ':', CONSTANT_BUILTIN, 'null', OPERATOR, ',', --
    STRING, '4', OPERATOR, ':', NUMBER, '.Inf', OPERATOR, ',', --
    STRING, '5', OPERATOR, ':', DEFAULT, 'two words', OPERATOR, ',', --
    STRING, '6', OPERATOR, ':', NUMBER .. '.timestamp', '2000-01-01T12:00:00.0Z', --
    OPERATOR, '}', --
    OPERATOR, '-', STRING, '-key - 5', OPERATOR, ':', OPERATOR, '{', --
    STRING, 'one', OPERATOR, ':', DEFAULT, 'two', OPERATOR, ',', --
    STRING, 'three four', OPERATOR, ':', DEFAULT, 'five six', --
    OPERATOR, '}', --
    OPERATOR, '?', OPERATOR, '-', DEFAULT, 'item 1', --
    OPERATOR, ':', OPERATOR, '-', DEFAULT, 'item 2', --
    OPERATOR, '-', OPERATOR, '{', --
    STRING, 'ok', OPERATOR, ':', DEFAULT, 'ok@', OPERATOR, ',', --
    ERROR, '@', OPERATOR, ':', ERROR, '@', --
    OPERATOR, '}', --
    STRING, 'literal', OPERATOR, ':', --
    DEFAULT, '|\n  line 1\n\n  - line 2\n  [line, 3]\n  #line 4\n  ---\n', --
    STRING, 'flow', OPERATOR, ':', --
    DEFAULT, '>\n  {line: 5}\n  ? - line 6\n  @line 7\n  %line 8\n  ...', --
    OPERATOR, '-', STRING, 'foo', OPERATOR, ':', DEFAULT, 'bar', --
    STRING, 'baz', OPERATOR, ':', DEFAULT, '|\n   quux', --
    OPERATOR, '-', DEFAULT, 'foobar' --
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
    DEFAULT, '|\n\n   quux', --
    OPERATOR, '-', DEFAULT, 'foobar'
  }
  assert_lex(yaml, code:match('(|.+)$'), tags, DEFAULT)
end

-- Tests the Python lexer and fold by indentation.
function test_python()
  local python = lexer.load('python')

  -- Lexing tests.
  local code = [[
    # Comment.
    @decorator
    class Foo(Bar):
      """documentation"""

      def __init__(self, foo):
        super(Foo, self).__init__()

      def bar(): pass

    if __name__ == '__main__':
      a = -1 + 2.0e3 - 0x4_0 @ 5j
      b = u"foo"
      c = br"\n"
      print(Foo.__doc__)
      Foo().bar()
  ]]
  local tags = {
    COMMENT, '# Comment.', --
    ANNOTATION, '@decorator', --
    KEYWORD, 'class', CLASS, 'Foo', OPERATOR, '(', IDENTIFIER, 'Bar', OPERATOR, ')', OPERATOR, ':', --
    STRING, '"""documentation"""', --
    KEYWORD, 'def', --
    FUNCTION_BUILTIN .. '.special', '__init__', --
    OPERATOR, '(', IDENTIFIER, 'self', OPERATOR, ',', IDENTIFIER, 'foo', OPERATOR, ')', --
    OPERATOR, ':', --
    FUNCTION_BUILTIN, 'super', --
    OPERATOR, '(', --
    IDENTIFIER, 'Foo', --
    OPERATOR, ',', --
    IDENTIFIER, 'self', --
    OPERATOR, ')', --
    OPERATOR, '.', --
    FUNCTION_BUILTIN .. '.special', '__init__', OPERATOR, '(', OPERATOR, ')', --
    KEYWORD, 'def', FUNCTION, 'bar', OPERATOR, '(', OPERATOR, ')', OPERATOR, ':', KEYWORD, 'pass', --
    KEYWORD, 'if', --
    ATTRIBUTE, '__name__', --
    OPERATOR, '=', OPERATOR, '=', --
    STRING, "'__main__'", --
    OPERATOR, ':', --
    IDENTIFIER, 'a', --
    OPERATOR, '=', --
    NUMBER, '-1', --
    OPERATOR, '+', --
    NUMBER, '2.0e3', --
    OPERATOR, '-', --
    NUMBER, '0x4_0', --
    OPERATOR, '@', --
    NUMBER, '5j', --
    IDENTIFIER, 'b', OPERATOR, '=', STRING, 'u"foo"', --
    IDENTIFIER, 'c', OPERATOR, '=', STRING, 'br"\\n"', --
    FUNCTION_BUILTIN, 'print', --
    OPERATOR, '(', --
    IDENTIFIER, 'Foo', OPERATOR, '.', ATTRIBUTE, '__doc__', --
    OPERATOR, ')', --
    FUNCTION, 'Foo', OPERATOR, '(', OPERATOR, ')', --
    OPERATOR, '.', --
    FUNCTION_METHOD, 'bar', OPERATOR, '(', OPERATOR, ')' --
  }
  assert_lex(python, code, tags)

  -- Folding tests.
  code = [[
    class Foo:
      """Documentation
      """
      def foo():
        pass

      def bar(): pass

    if __name__ == '__main__':
      pass
  ]]
  local folds = {1, 4, -6, -8, 9}
  assert_fold_points(python, code, folds)
end

-- Tests output lexer.
function test_output()
  local output = lexer.load('output')
  local text = ([[
    > command
    /tmp/foo:1:2: error
    /tmp/bar.baz:12: warning: warn
    > exit status: 1

    lua: /tmp/quux.lua:34: error
    no error or warning here

    /tmp/foo.sh: line 2: message

    > python3
      File "/tmp/foo.py", line 10

    foo.d(5): Error: no property `foo` for type `Bar`

    "/tmp/foo.plt" line 1: invalid command

    java.lang.Exception: Stack trace
      at com.foo(Foo.java:23)

    No such file or directory in /tmp/foo.php on line 2

    C:\tmp\foo.cs(12, 34): error CS0000: message

    syntax error at /tmp/foo.pl line 7, near "foo"

    CMake Error at CMakeLists.txt:1:
      Parse error.  Expected ...
    -- Configuring incomplete, errors occurred!
  ]]):gsub('    ', '') -- strip indent
  local tags = {
    DEFAULT, '> command', --
    'filename', '/tmp/foo', DEFAULT, ':', --
    'line', '1', DEFAULT, ':', 'column', '2', DEFAULT, ': ', --
    'message', 'error', --
    'filename', '/tmp/bar.baz', DEFAULT, ':', --
    'line', '12', DEFAULT, ': ', --
    'message', 'warning: warn', --
    DEFAULT, '> exit status: 1',
    --
    DEFAULT, 'lua', DEFAULT, ': ', --
    'filename', '/tmp/quux.lua', DEFAULT, ':', --
    'line', '34', DEFAULT, ': ', --
    'message', 'error', --
    DEFAULT, 'no error or warning here',
    --
    'filename', '/tmp/foo.sh', DEFAULT, ': ', --
    DEFAULT, 'line ', 'line', '2', DEFAULT, ': ', --
    'message', 'message',
    --
    DEFAULT, '> python3', --
    DEFAULT, 'File "', 'filename', '/tmp/foo.py', DEFAULT, '", ', --
    DEFAULT, 'line ', 'line', '10',
    --
    'filename', 'foo.d', DEFAULT, '(', 'line', '5', DEFAULT, ')', DEFAULT, ': ', --
    'message', 'Error: no property `foo` for type `Bar`',
    --
    DEFAULT, '"', 'filename', '/tmp/foo.plt', DEFAULT, '" ', --
    DEFAULT, 'line ', 'line', '1', DEFAULT, ': ', --
    'message', 'invalid command',
    --
    DEFAULT, 'java.lang.Exception: Stack trace', --
    DEFAULT, 'at com.foo', DEFAULT, '(', --
    'filename', 'Foo.java', DEFAULT, ':', 'line', '23', DEFAULT, ')',
    --
    'message', 'No such file or directory', DEFAULT, ' in ', --
    'filename', '/tmp/foo.php', DEFAULT, ' on ', DEFAULT, 'line ', 'line', '2',
    --
    'filename', 'C:\\tmp\\foo.cs', --
    DEFAULT, '(', 'line', '12', DEFAULT, ', ', 'column', '34', DEFAULT, ')', DEFAULT, ': ', --
    'message', 'error CS0000: message',
    --
    'message', 'syntax error', DEFAULT, ' at ', --
    'filename', '/tmp/foo.pl', DEFAULT, ' line ', 'line', '7', --
    DEFAULT, ', near "foo"',
    --
    DEFAULT, 'CMake Error at ', --
    'filename', 'CMakeLists.txt', DEFAULT, ':', 'line', '1', DEFAULT, ':', --
    DEFAULT, 'Parse error.  Expected ...', DEFAULT, '-- Configuring incomplete, errors occurred!'
  }
  assert_lex(output, text, tags)
  local marks = {}
  for _, i in ipairs{2, 6, 9, 12, 14, 16, 19, 21, 23, 25, 27} do marks[i] = 1 end -- errors
  for _, i in ipairs{3} do marks[i] = 2 end -- warnings
  for k, v in pairs(marks) do
    assert(lexer.line_state[k] == v, string.format('line_state[%d] ~= %d', k, v))
  end
  for k, v in pairs(lexer.line_state) do
    assert(marks[k] == v, string.format('marks[%d] ~= %d', k, v))
  end
end

-- Tests LaTeX lexer, particularly its folding.
function test_latex()
  local latex = lexer.load('latex')
  local code = [[
    \begin{document}
      \begin{align} % should inherit environment folding
      E = mc^2
      \end{align}
    \end{document}
  ]]
  local tags = {
    'environment', '\\begin{document}', --
    'environment.math', '\\begin{align}', COMMENT, '% should inherit environment folding', --
    DEFAULT, 'E', DEFAULT, '=', DEFAULT, 'm', DEFAULT, 'c', DEFAULT, '^', DEFAULT, '2', --
    'environment.math', '\\end{align}', --
    'environment', '\\end{document}' --
  }
  assert_lex(latex, code, tags)
  local folds = {1, 2, -4, -5}
  assert_fold_points(latex, code, folds)
end

function test_legacy()
  local lex = lexer.new('test')
  local ws = lexer.token(lexer.WHITESPACE, lexer.space^1)
  lex:add_rule('whitespace', ws) -- should call lex:modify_rule()
  assert(lex._rules['whitespace'] == ws)
  lex:add_rule('keyword', lexer.token(KEYWORD, lexer.word_match('foo bar baz')))
  lex:add_rule('number', lexer.token(NUMBER, lexer.number))
  lex:add_rule('preproc', lexer.token(PREPROCESSOR, lexer.starts_line(lexer.to_eol('#'))))
  lex:add_style('whatever', lexer.styles.keyword .. {fore = lexer.colors.red, italic = true})
  local code = "foo 1 bar 2 baz 3\n#quux"
  local tags = {
    KEYWORD, 'foo', --
    NUMBER, '1', --
    KEYWORD, 'bar', --
    NUMBER, '2', --
    KEYWORD, 'baz', --
    NUMBER, '3', --
    PREPROCESSOR, '#quux'
  }
  assert_lex(lex, code, tags)
end

function test_detect()
  assert(lexer.detect('foo.lua') == 'lua')
  assert(lexer.detect('foo.c') == 'ansi_c')
  assert(not lexer.detect('foo.txt'))
  assert(lexer.detect('foo', '#!/bin/sh') == 'bash')
  assert(not lexer.detect('foo', '/bin/sh'))

  lexer.detect_extensions.luadoc = 'lua'
  assert(lexer.detect('foo.luadoc') == 'lua')
  assert(lexer.detect('foo.m') == 'objective_c')
  lexer.detect_extensions.m = 'matlab' -- override
  assert(lexer.detect('foo.m') == 'matlab')

  assert(lexer.detect('CMakeLists.txt') == 'cmake') -- not text

  -- Simulate SCI_PRIVATELEXERCALL.
  assert(not lexer.detect()) -- should not error or anything
  lexer.property['lexer.scintillua.filename'] = 'foo.lua'
  assert(lexer.detect() == 'lua')
  lexer.property['lexer.scintillua.line'] = '#!/usr/env/ruby'
  assert(lexer.detect() == 'ruby') -- line detection has priority over filename detection
end

function test_lua51()
  local p = io.popen(
    [[cd lexers && lua5.1 -e 'lexer=require"lexer"' -e 'print(unpack(lexer.load("lua"):lex("_G")))']])
  local output = p:read('a')
  p:close()
  assert(output:find(CONSTANT_BUILTIN .. '\t3', 1, true))
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
