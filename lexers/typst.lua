local lexer = require('lexer')
local token = lexer.token
local P, S, B, R, C = lpeg.P, lpeg.S, lpeg.B, lpeg.R, lpeg.C

local lex = lexer.new(...)

local hspace = lexer.space - '\n'
local blank_line = '\n' * hspace^0 * ('\n' + P(-1))
local punct_space = lexer.punct + lexer.space

local function flanked_range(s, not_inword)
  local fl_char = lexer.any - s - lexer.space
  local left_fl = B(punct_space - s) * s * #fl_char + s * #(fl_char - lexer.punct)
  local right_fl = B(lexer.punct) * s * #(punct_space - s) + B(fl_char) * s
  return left_fl * (lexer.any - blank_line - (not_inword and s * #punct_space or s))^0 * right_fl
end

local asterisk_strong = flanked_range('*', true)
lex:add_rule('strong', lex:tag(lexer.BOLD, asterisk_strong))

local underscore_em = flanked_range('_', true)
lex:add_rule('em', lex:tag(lexer.ITALIC, underscore_em))

local function h(n)
  local equals = P('=')^n
  local standalone = lexer.starts_line(hspace^0 * equals * hspace^1) * lexer.to_eol(lexer.nonnewline)
  local bracketed = P('[') * (lexer.space+'\n')^0 * equals * hspace^0 * (lexer.any - P(']'))^0 * (lexer.space+'\n')^0 * P(']')
  return lex:tag(string.format('%s.h%s', lexer.HEADING, n), standalone + bracketed)
end
lex:add_rule('header', h(6) + h(5) + h(4) + h(3) + h(2) + h(1))

local raw_str = lexer.range('`', false, false)
local dq_str = lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, raw_str + dq_str))

lex:add_rule('comment', lex:tag(lexer.COMMENT,
  lexer.range('/*', '*/') + lexer.to_eol('//')))

lex:add_rule('list', lex:tag(lexer.LIST,
  lexer.starts_line(lexer.digit^1 * '.' + S('+-'), true) * S(' \t')))

-- TODO: The keywords currently are matched ANYWHERE (even in plain text), fix this later
local keyword_condition = B('#') * lex:word_match(lexer.KEYWORD)
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- NOTE: same goes for the functions and fields
local func = lex:tag(lexer.FUNCTION, (B('.') + B('#')) * lexer.word * P('()'))
lex:add_rule('function', func)

local field = lex:tag('FIELD', B('.') * lexer.word * (lexer.any - P('(')))
lex:add_rule('field', field)

local number = lexer.number * P('i')^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, number))

lex:add_rule('markup', lex:tag(lexer.TAG, (S('[]'))))

local math_block = P('$') * (lexer.space+'\n')^0 * (lexer.any - P('$'))^0 * (lexer.space+'\n')^0 * P('$')
lex:add_rule('math', lex:tag('environment.math', math_block))

-- Code blocks
local code_block = lexer.range('```', '```', false)
lex:add_rule('code_block', lex:tag(lexer.PREPROCESSOR, code_block))

lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%&|^<>=!~:;.,()[]{}')))

lex:set_word_list(lexer.KEYWORD, {
  'if', 'else', 'for', 'while', 'let', 'set', 'import', 'include', 'return',
  'true', 'false', 'none', 'auto', 'not', 'in', 'and', 'or', 'as', 'show'
})


--[[
-- FIXME: Only match within math mode
lex:set_word_list(lexer.FUNCTION, {
  'min', 'max', 'abs', 'sqrt', 'sin', 'cos', 'tan', 'log', 'exp'
})
]]

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.PREPROCESSOR, '```', '```')
lexer.property['scintillua.comment'] = '//'

return lex

