-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Pascal LPeg Lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '//' * l.nonnewline_esc^0
local bblock_comment = '{' * (l.any - '}')^0 * P('}')^-1
local pblock_comment = '(*' * (l.any - '*)')^0 * P('*)')^-1
local comment = token('comment', line_comment + bblock_comment + pblock_comment)

-- strings
local string =
  token('string', S('uUrR')^-1 * l.delimited_range("'", nil, true, false, '\n'))

-- numbers
local number = token('number', (l.float + l.integer) * S('LlDdFf')^-1)

-- keywords
local keyword = token('keyword', word_match({
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
local func = token('function', word_match({
  'chr', 'ord', 'succ', 'pred', 'abs', 'round', 'trunc', 'sqr', 'sqrt',
  'arctan', 'cos', 'sin', 'exp', 'ln', 'odd', 'eof', 'eoln'
}, nil, true))

-- types
local type = token('type', word_match({
  'shortint', 'byte', 'char', 'smallint', 'integer', 'word', 'longint',
  'cardinal', 'boolean', 'bytebool', 'wordbool', 'longbool', 'real', 'single',
  'double', 'extended', 'comp', 'currency', 'pointer'
}, nil, true))

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('.,;^@:=<>+-/*()[]'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'type', type },
  { 'string', string },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
