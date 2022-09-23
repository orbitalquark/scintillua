-- Copyright 2006-2022 Mitchell. See LICENSE.
-- Django LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN)))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"', false, false)))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S(':,.|')))

-- Embed Django in HTML.
local html = lexer.load('html')
html:add_rule('django_comment', lex:tag(lexer.COMMENT, lexer.range('{#', '#}', true)))
local django_start_rule = lex:tag(lexer.TAG .. '.django', '{' * S('{%'))
local django_end_rule = lex:tag(lexer.TAG .. '.django', S('%}') * '}')
html:embed(lex, django_start_rule, django_end_rule)

-- Fold points.
lex:add_fold_point(lexer.TAG .. '.django', '{{', '}}')
lex:add_fold_point(lexer.TAG .. '.django', '{%', '%}')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
  'as', 'block', 'blocktrans', 'by', 'endblock', 'endblocktrans', 'comment', 'endcomment', 'cycle',
  'date', 'debug', 'else', 'extends', 'filter', 'endfilter', 'firstof', 'for', 'endfor', 'if',
  'endif', 'ifchanged', 'endifchanged', 'ifnotequal', 'endifnotequal', 'in', 'load', 'not', 'now',
  'or', 'parsed', 'regroup', 'ssi', 'trans', 'with', 'widthratio'
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
  'add', 'addslashes', 'capfirst', 'center', 'cut', 'date', 'default', 'dictsort',
  'dictsortreversed', 'divisibleby', 'escape', 'filesizeformat', 'first', 'fix_ampersands',
  'floatformat', 'get_digit', 'join', 'length', 'length_is', 'linebreaks', 'linebreaksbr',
  'linenumbers', 'ljust', 'lower', 'make_list', 'phone2numeric', 'pluralize', 'pprint', 'random',
  'removetags', 'rjust', 'slice', 'slugify', 'stringformat', 'striptags', 'time', 'timesince',
  'title', 'truncatewords', 'unordered_list', 'upper', 'urlencode', 'urlize', 'urlizetrunc',
  'wordcount', 'wordwrap', 'yesno'
})

lexer.property['scintillua.comment'] = '{#|#}'

return lex
