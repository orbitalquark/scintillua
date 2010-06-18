-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ragel LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('ragel_whitespace', space^1)

-- comment
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local set = delimited_range('[]', '\\', true)
local regex = delimited_range('/', '\\', true) * P('i')^-1
local string = token('string', sq_str + dq_str + set + regex)

-- numbers
local number = token('number', digit^1)

-- built-in machines
local builtin_machine = word_match(word_list{
  'any', 'ascii', 'extend', 'alpha', 'alnum', 'lower', 'upper', 'digit',
  'xdigit', 'cntrl', 'graph', 'print', 'punct', 'space', 'zlen', 'empty'
})
builtin_machine = token('ragel_builtin_machine', builtin_machine)

-- keywords
local keyword = word_match(word_list{
  'machine', 'include', 'import', 'action', 'getkey', 'access', 'variable',
  'prepush', 'postpop', 'write', 'data', 'init', 'exec', 'exports', 'export'
})
keyword = token('keyword', keyword)

local identifier = word

-- actions
local transition =
  token('ragel_transition', ((S('>@$%') * S('/!^~*')^-1 + '<' * (S('/!^~*')^-1 +
        '>' * S('/!^~*')^-1)) + S('-=') * '>' * space^0) * identifier^-1)
local action_def =
  #P('action') * keyword * ws * token('ragel_action', identifier)
local action = action_def + transition

-- operators
local operator = token('operator', S(',|&-.<:>*?+!^();'))

local cpp = require 'cpp'

function LoadTokens()
  cpp.LoadTokens()
  local ragel = ragel
  add_token(ragel, 'ragel_whitespace', ws)
  add_token(ragel, 'comment', comment)
  add_token(ragel, 'string', string)
  add_token(ragel, 'number', number)
  add_token(ragel, 'ragel_builtin_machine', builtin_machine)
  add_token(ragel, 'action', action)
  add_token(ragel, 'keyword', keyword)
  --add_token(ragel, 'identifier', identifier)
  add_token(ragel, 'operator', operator)
  add_token(ragel, 'any_char', token('ragel_default', any - '}%%'))

  -- embedding C/C++ in Ragel
  ragel.in_cpp = false
  cpp.TokenPatterns.operator = token('operator', S('+-/*%<>!=&|?:;.()[]') +
    '{' * P(function(input, index)
      -- if we're in embedded C/C++ in Ragel, increment the brace_count
      if cpp.in_ragel then cpp.brace_count = cpp.brace_count + 1 end
      return index
    end) +
    '}' * P(function(input, index)
      -- if we're in embedded C/C++ in Ragel and the brace_count is zero,
      -- this is the end of the embedded C/C++; ignore this bracket so the
      -- cpp.EmbeddedIn[ragel._NAME].end_token is matched.
      -- otherwise decrement the brace_count
      if cpp.in_ragel then
        if cpp.brace_count == 0 then return nil end
        cpp.brace_count = cpp.brace_count - 1
      end
      return index
    end))
  -- don't match a closing bracket so cpp.EmbeddedIn[ragel._NAME].end_token can
  -- be matched
  cpp.TokenPatterns.any_char = token('any_char', any - '}')
  local start_token = token('operator', '{' * P(function(input, index)
    -- if we're in embedded Ragel in C/C++, and this is the first {, we have
    -- embedded C/C++ in Ragel; set the flag
    if cpp.in_ragel and not ragel.in_cpp then
      ragel.in_cpp = true
      return index
    end
  end))
  local end_token = token('operator', '}' * P(function(input, index)
    -- if we're in embedded C/C++ in Ragel and the brace_count is zero, this
    -- is the end of embedded C/C++; unset the flag
    if cpp.in_ragel and cpp.brace_count == 0 then
      ragel.in_cpp = false
      return index
    end
  end))
  make_embeddable(cpp, ragel, start_token, end_token)
  embed_language(ragel, cpp)

  -- embedding Ragel in C/C++
  cpp.in_ragel = false
  cpp.brace_count = 0
  start_token = token('ragel_tag', '%%{' * P(function(input, index)
    -- set the flag for embedded Ragel in C/C++
    cpp.in_ragel = true
    return index
  end))
  end_token = token('ragel_tag', '}%%' * P(function(input, index)
    -- unset the flag for embedded Ragel in C/C++
    cpp.in_ragel = false
    return index
  end))
  make_embeddable(ragel, cpp, start_token, end_token)
  -- because this is a doubly-embedded language lexer (cpp -> ragel -> cpp),
  -- we need the structure:
  -- ragel_start * (cpp_start * cpp_token * cpp_end + ragel_token) * ragel_end +
  --   cpp_token
  -- embed_language will not do this, because when rebuild_token is called on
  -- ragel, the C/C++ embedded tokens are not considered; Ragel is embedded in
  -- C/C++, but the fact that C/C++ should be embedded in Ragel is forgotten
  local ecpp = cpp.EmbeddedIn[ragel._NAME]
  local eragel = ragel.EmbeddedIn[cpp._NAME]
  eragel.token =
    ecpp.start_token * ecpp.token^0 * ecpp.end_token^-1 + eragel.token
  embed_language(cpp, ragel)

  UseOtherTokens = cpp.Tokens
end

function LoadStyles()
  --cpp.LoadStyles()
  add_style('ragel_whitespace', style_nothing)
  add_style('ragel_builtin_machine', style_keyword)
  add_style('ragel_transition', style_definition)
  add_style('ragel_action', style_definition)
  add_style('ragel_default', style_nothing)
  add_style('ragel_tag', style_embedded)
end
