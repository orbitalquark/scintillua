-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Pascal LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local bblock_comment = '{' * (any - '}')^0 * P('}')^-1
local pblock_comment = '(*' * (any - '*)')^0 * P('*)')^-1
local comment = token('comment', line_comment + bblock_comment + pblock_comment)

-- strings
local string =
  token('string', S('uUrR')^-1 * delimited_range("'", nil, true, false, '\n'))

-- numbers
local number = token('number', (float + integer) * S('LlDdFf')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'and', 'array', 'as', 'at', 'asm', 'begin', 'case', 'class', 'const',
  'constructor', 'destructor', 'dispinterface', 'div', 'do', 'downto', 'else',
  'end', 'except', 'exports', 'file', 'final', 'finalization', 'finally', 'for',
  'function', 'goto', 'if', 'implementation', 'in', 'inherited',
  'initialization', 'inline', 'interface', 'is', 'label', 'mod', 'not',
  'object', 'of', 'on', 'or', 'out', 'packed', 'procedure', 'program',
  'property', 'raise', 'record', 'repeat', 'resourcestring', 'set', 'sealed',
  'shl', 'shr', 'static', 'string', 'then', 'threadvar', 'to', 'try', 'type',
  'unit', 'unsafe', 'until', 'uses', 'var', 'while', 'with', 'xor',
  'absolute', 'abstract', 'assembler', 'automated', 'cdecl', 'contains',
  'default', 'deprecated', 'dispid', 'dynamic', 'export', 'external', 'far',
  'forward', 'implements', 'index', 'library', 'local', 'message', 'name',
  'namespaces', 'near', 'nodefault', 'overload', 'override', 'package',
  'pascal', 'platform', 'private', 'protected', 'public', 'published', 'read',
  'readonly', 'register', 'reintroduce', 'requires', 'resident', 'safecall',
  'stdcall', 'stored', 'varargs', 'virtual', 'write', 'writeln', 'writeonly',
  'false', 'nil', 'self', 'true'
}, nil, true))

-- functions
local func = token('function', word_match(word_list{
  'chr', 'ord', 'succ', 'pred', 'abs', 'round', 'trunc', 'sqr', 'sqrt',
  'arctan', 'cos', 'sin', 'exp', 'ln', 'odd', 'eof', 'eoln'
}, nil, true))

-- types
local type = token('type', word_match(word_list{
  'shortint', 'byte', 'char', 'smallint', 'integer', 'word', 'longint',
  'cardinal', 'boolean', 'bytebool', 'wordbool', 'longbool', 'real', 'single',
  'double', 'extended', 'comp', 'currency', 'pointer'
}, nil, true))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('.,;^@:=<>+-/*()[]'))

function LoadTokens()
  local pascal = pascal
  add_token(pascal, 'whitespace', ws)
  add_token(pascal, 'keyword', keyword)
  add_token(pascal, 'function', func)
  add_token(pascal, 'type', type)
  add_token(pascal, 'string', string)
  add_token(pascal, 'identifier', identifier)
  add_token(pascal, 'comment', comment)
  add_token(pascal, 'number', number)
  add_token(pascal, 'operator', operator)
  add_token(pascal, 'any_char', any_char)
end
