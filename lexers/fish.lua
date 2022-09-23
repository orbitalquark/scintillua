-- Copyright 2015-2022 Jason Schindler. See LICENSE.
-- Fish (http://fishshell.com/) script LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Variables.
lex:add_rule('variable', lex:tag(lexer.VARIABLE, '$' * (lexer.word + lexer.range('{', '}', true))))

-- Strings.
local sq_str = lexer.range("'", false, false)
local dq_str = lexer.range('"')
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Shebang.
lex:add_rule('shebang', lex:tag(lexer.COMMENT .. '.shebang', lexer.to_eol('#!/')))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('#')))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=!<>+-/*^&|~.,:;?()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'begin', 'end')
lex:add_fold_point(lexer.KEYWORD, 'for', 'end')
lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point(lexer.KEYWORD, 'switch', 'end')
lex:add_fold_point(lexer.KEYWORD, 'while', 'end')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
  'alias', 'and', 'begin', 'bg', 'bind', 'block', 'break', 'breakpoint', 'builtin', 'case', 'cd',
  'command', 'commandline', 'complete', 'contains', 'continue', 'count', 'dirh', 'dirs', 'echo',
  'else', 'emit', 'end', 'eval', 'exec', 'exit', 'fg', 'fish', 'fish_config', 'fishd',
  'fish_indent', 'fish_pager', 'fish_prompt', 'fish_right_prompt', 'fish_update_completions', 'for',
  'funced', 'funcsave', 'function', 'functions', 'help', 'history', 'if', 'in', 'isatty', 'jobs',
  'math', 'mimedb', 'nextd', 'not', 'open', 'or', 'popd', 'prevd', 'psub', 'pushd', 'pwd', 'random',
  'read', 'return', 'set', 'set_color', 'source', 'status', 'switch', 'test', 'trap', 'type',
  'ulimit', 'umask', 'vared', 'while'
})

lexer.property['scintillua.comment'] = '#'

return lex
