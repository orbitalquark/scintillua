local lexer = require('lexer')
local token = lexer.token
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

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

local function build_rules(pre)
  local hash_word = -B('\\') * pre * lexer.word
  local keyword_match = -B('\\') * pre * lex:word_match(lexer.KEYWORD)

  return {
    in_code = -B('\\') * lexer.range('`', false, false),
    dq_string = -B('\\') * lexer.range('"', true),
    string = -B('\\') * lexer.range('`', false, false) + -B('\\') * lexer.range('"', true),
    
    hash_word = hash_word,
    keyword_match = keyword_match,
    
    iden = lex:tag(lexer.IDENTIFIER, hash_word),
    mod_func = lex:tag(lexer.KEYWORD, hash_word) * lexer.space^1 * 
               lex:tag(lexer.FUNCTION, lexer.word) * lex:tag(lexer.OPERATOR, S('[(')),
    func = lex:tag(lexer.FUNCTION, hash_word) * lex:tag(lexer.OPERATOR, S('[(')),
    method = lex:tag(lexer.IDENTIFIER, hash_word) *
             lex:tag(lexer.OPERATOR, P('.')) *
             lex:tag(lexer.FUNCTION_METHOD, lexer.word) * S('[('),
    field = lex:tag(lexer.IDENTIFIER, hash_word) *
            lex:tag(lexer.OPERATOR, P('.')) *
            lex:tag('FIELD', lexer.word) * -S('[('),
    operator = lex:tag(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}')),
    label = -B('\\') * lex:tag(lexer.LABEL, P('<') * lexer.word * P('>')),
    label_two = -B('\\') * lex:tag(lexer.LABEL, P('@') * lexer.word),
    
    italic = -B('\\') * lex:tag(lexer.ITALIC, lexer.range('_', '_')),
    bold = -B('\\') * lex:tag(lexer.BOLD, lexer.range('*', '*')),
    
    math = -B('\\') * lexer.range('$', false, false),
    code = lexer.range('```', '```', false),
    list = lex:tag(lexer.LIST, lexer.starts_line(lexer.digit^1 * '.' + S('+-'), true) * S(' \t')),
    numeric_value = lexer.number^1 * ('.' * lexer.number^1)^-1 * lex:word_match('UNITS')^-1,
    comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/') + lexer.to_eol('//')),
    
    keyword = lex:tag(lexer.KEYWORD, keyword_match),
    
    header = header(6) + header(5) + header(4) + header(3) + header(2) + header(1)
  }
end

local emb_lex = lexer.new('scripting')

--[[
 #{ ... }
   OR
 #let x = { ... }
]]
local start = (lex:tag(lexer.KEYWORD, P('#') * lex:word_match(lexer.KEYWORD)) *
	      #((lexer.any - S('{;\n'))^1 * S('{') * lexer.space^0)) +
	      lex:tag(lexer.OPERATOR,P('#') * S('{'))
local embed_start = lex:tag('emb_tag', start)
local embed_end = lexer:tag('emb_tag', S('}'))

local function add_rules(lexer_obj, pre)
  local rules = build_rules(pre)
  lexer_obj:add_rule('header', rules.header)
  lexer_obj:add_rule('field', rules.field)
  lexer_obj:add_rule('bold', rules.bold)
  lexer_obj:add_rule('italic', rules.italic)
  lexer_obj:add_rule('function', rules.mod_func + rules.func)
  lexer_obj:add_rule('method', rules.method)
  lexer_obj:add_rule('label', rules.label + rules.label_two)
  lexer_obj:add_rule('code', lex:tag(lexer.CODE, rules.code))
  lexer_obj:add_rule('string', lex:tag(lexer.STRING, rules.string))
  lexer_obj:add_rule('math', lex:tag('environment.math', rules.math))
  lexer_obj:add_rule('keyword', rules.keyword)
  lexer_obj:add_rule('identifier', rules.iden)
  lexer_obj:add_rule('number', lex:tag(lexer.NUMBER, rules.numeric_value))
  lexer_obj:add_rule('list', rules.list)
  lexer_obj:add_rule('comment', rules.comment)
  lexer_obj:add_rule('operator', rules.operator)
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
