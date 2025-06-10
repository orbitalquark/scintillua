local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)
-- Keep things simple for now and only allow bold and italic in non-code mode
local italic = -B('\\') * lex:tag(lexer.ITALIC, lexer.range('_', '_'))
local bold = -B('\\') * lex:tag(lexer.BOLD, lexer.range('*', '*'))

lex:add_rule('bold', bold)
lex:add_rule('italic', italic)

local function header(level)
  local hspace = (lexer.space - '\n')
  local equals_signs = P('=')^level
  -- Stupid header rule for now
  local header = (lexer.starts_line(hspace^0 * equals_signs * hspace^1) * (lexer.any - S('\n'))^0)
--[[
  local header = (lexer.starts_line(hspace^0 * equals_signs * hspace^1) * (lexer.any - S('#@<\n'))^0) +
				(((B('[') * hspace^0 * equals_signs * hspace^1)) *
				(lexer.any - S('#@<'))^0)
]]
  return lex:tag(string.format('%s.h%s', lexer.HEADING, level), header)
end

local emb_lex = lexer.new('typst_scripting')

--[[
 #{ ... }
   OR
 #let x = { ... }
]]
-- This is very limited, since it would only work correctly if no nested structures (w/ brackets) are found inside
-- otherwise (if they're found inside), the first closing bracket of that nested structure would close the whole embedded
-- script, causing the rest of the script to not be treated as a part of embedded script
local start = (lex:tag(lexer.KEYWORD, P('#') * lex:word_match(lexer.KEYWORD)) *
	      #((lexer.any - S('{;\n'))^1 * S('{') * lexer.space^0)) +
	      lex:tag(lexer.OPERATOR,P('#') * S('{'))

local embed_start = lex:tag(lexer.EMBEDDED, start)
local embed_end = lexer:tag(lexer.EMBEDDED, S('}'))

local function add_rules(lexer_obj, pre)
  local hash_word = -B('\\') * pre * lexer.word

  local in_code = -B('\\') * lexer.range('`', false, false)
  local dq_string = -B('\\') * lexer.range('"', true)
  local string_rule = -B('\\') * lexer.range('`', false, false) + -B('\\') * lexer.range('"', true)
  
  
  local iden = lex:tag(lexer.IDENTIFIER, hash_word)
  local mod_func = lex:tag(lexer.KEYWORD, hash_word) * lexer.space^1 * 
             lex:tag(lexer.FUNCTION, lexer.word) * lex:tag(lexer.OPERATOR, S('[('))
  local func = lex:tag(lexer.FUNCTION, hash_word) * lex:tag(lexer.OPERATOR, S('[('))
  local method = lex:tag(lexer.IDENTIFIER, hash_word) *
           lex:tag(lexer.OPERATOR, P('.')) *
           lex:tag(lexer.FUNCTION_METHOD, lexer.word) * lex:tag(lexer.OPERATOR, S('[('))
  local field = lex:tag(lexer.IDENTIFIER, hash_word) *
          lex:tag(lexer.OPERATOR, P('.')) *
          lex:tag('FIELD', lexer.word) * -S('[(')
  local operator = lex:tag(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}'))
  local label = -B('\\') * lex:tag(lexer.LABEL, P('<') * lexer.word * P('>'))
  local label_two = -B('\\') * lex:tag(lexer.LABEL, P('@') * lexer.word)
  local link = P('http') * P('s')^-1 * P(':') * (lexer.word + S('.:/'))^1
  
  local math_rule = -B('\\') * lexer.range('$', false, false)
  local code = lexer.range('```', '```', false)
  local list = lex:tag(lexer.LIST, lexer.starts_line(lexer.digit^1 * '.' + S('+-'), true) * S(' \t'))
  local comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/') + lexer.to_eol('//'))
  
  local keyword_match = -B('\\') * pre * lex:word_match(lexer.KEYWORD)
  local keyword = lex:tag(lexer.KEYWORD, keyword_match)
  
  local header = header(6) + header(5) + header(4) + header(3) + header(2) + header(1)
  lexer_obj:add_rule('header', header)
  lexer_obj:add_rule('field', field)
  lexer_obj:add_rule('function', mod_func + func)
  lexer_obj:add_rule('method', method)
  lexer_obj:add_rule('label', label + label_two)
  lexer_obj:add_rule('code', lex:tag(lexer.CODE, code))
  lexer_obj:add_rule('string', lex:tag(lexer.STRING, string_rule))
  lexer_obj:add_rule('link', lex:tag(lexer.LINK, link))
  lexer_obj:add_rule('math', lex:tag('environment.math', math_rule))
  lexer_obj:add_rule('keyword', keyword)
  lexer_obj:add_rule('identifier', iden)

  -- TODO: Do we really need to not tag a number if procceded by an alpha?
  -- TODO: limit numeric values to only be tagged when used as args, assigned values
  -- numeric_value = (lexer.number^1 * ('.' * lexer.number^1)^-1 * lex:word_match('UNITS')^-1),
  --lexer_obj:add_rule('number', lex:tag(lexer.NUMBER, numeric_value))

  lexer_obj:add_rule('list', list)
  lexer_obj:add_rule('comment', comment)
  lexer_obj:add_rule('operator', operator)
end

-- Keywords, functions... don't need '#' when in code
-- the character `#` is not valid in code
-- TODO: only enable styling and text related rules when in []
add_rules(emb_lex, '')

lex:embed(emb_lex, embed_start, embed_end)

add_rules(lex, '#')


lex:set_word_list(lexer.KEYWORD, {
  'if', 'else', 'for', 'while', 'let', 'set', 'import', 'include', 'return',
  'true', 'false', 'none', 'auto', 'not', 'in', 'and', 'or', 'as', 'show'
})

lex:set_word_list('UNITS', {'em', 'in', '%', 'mm', 'deg', 'rad', 'cm', 'pt', 'fr'})

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.PREPROCESSOR, '```', '```')
lexer.property['scintillua.comment'] = '//'

return lex
