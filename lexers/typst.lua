local lexer = require('lexer')
local token = lexer.token
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

local horizontal_space = lexer.space - '\n'

local keyword_match = lex:word_match(lexer.KEYWORD) * #' '

local bold_text = -B('\\') * lex:tag(lexer.BOLD, lexer.range('*', '*'))
lex:add_rule('bold', bold_text)
local italic_text = -B('\\') * lex:tag(lexer.ITALIC, lexer.range('_', '_'))
lex:add_rule('italic', italic_text)


local function header(level)
  local equals_signs = P('=')^level
  local standalone_header = lexer.starts_line(horizontal_space^0 * equals_signs * horizontal_space^1) * (lexer.any - S('#@<'))^0
  local bracketed_header = P('[') * (lexer.space + '\n')^0 * equals_signs * horizontal_space^0 * (lexer.any - P(']'))^0 * (lexer.space + '\n')^0 * P(']')
  return lex:tag(string.format('%s.h%s', lexer.HEADING, level), standalone_header + bracketed_header)
end
lex:add_rule('header', header(6) + header(5) + header(4) + header(3) + header(2) + header(1))

local label_definition = -B('\\') * lex:tag('LABEL', P('<') * lexer.word * P('>'))
local label_call = -B('\\') * lex:tag('LABEL', P('@') * lexer.word)
lex:add_rule('label', label_definition + label_call)

local inline_code = lexer.range('`', false, false)
local double_quote_string = lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, inline_code + double_quote_string))

lex:add_rule('comment', lex:tag(lexer.COMMENT,
  lexer.range('/*', '*/') + lexer.to_eol('//')))

lex:add_rule('list', lex:tag(lexer.LIST, lexer.starts_line(lexer.digit^1 * '.' + S('+-'), true) * S(' \t')))

local function_call = -B('\\') * '#' * (lex:tag(lexer.FUNCTION, lexer.word) * #S('(['))
lex:add_rule('function', function_call)

local function_method = lex:tag(lexer.FUNCTION_METHOD, (B('.')) * lexer.word * #P('('))
lex:add_rule('function_method', function_method)

lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, -B('\\') * '#' * -keyword_match * lexer.word * (-S('(') * -(P('.') * lexer.word))))
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, -B('\\') * '#' * keyword_match))

local field_access = lex:tag('FIELD', B('.') * lexer.word * (lexer.any - P('(')))
lex:add_rule('field', field_access)


local numeric_value = lexer.number^1 * ('.' * lexer.number^1)^-1 * lex:word_match('UNITS')^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, numeric_value))

lex:add_rule('markup', lex:tag(lexer.TAG, (S('[]'))))

local math_environment = P('$') * (lexer.space + '\n')^0 * (lexer.any - P('$'))^0 * (lexer.space + '\n')^0 * P('$')
lex:add_rule('math', lex:tag('environment.math', math_environment))

local code_block = lexer.range('```', '```', false)
lex:add_rule('code_block', lex:tag(lexer.CODE, code_block))

lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%&|^<>=!~:;.,()[]{}')))

lex:set_word_list(lexer.KEYWORD, {
  'if', 'else', 'for', 'while', 'let', 'set', 'import', 'include', 'return',
  'true', 'false', 'none', 'auto', 'not', 'in', 'and', 'or', 'as', 'show'
})

lex:set_word_list('UNITS', {'em', 'in', '%', 'mm', 'cm', 'pt', 'fr'})

--[[
-- FIXME: Only match within math mode, for now deal with math block as whole tag instead
lex:set_word_list(lexer.FUNCTION, {
  'min', 'max', 'abs', 'sqrt', 'sin', 'cos', 'tan', 'log', 'exp'
})
]]

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.PREPROCESSOR, '```', '```')
lexer.property['scintillua.comment'] = '//'

return lex
