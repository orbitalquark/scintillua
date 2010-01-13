-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Python LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

local lit_newline = P('\r')^-1 * P('\n')

-- comments
local comment = token('comment', '#' * nonnewline_esc^0)

-- strings
local sq_str = P('u')^-1 * delimited_range("'", '\\', true, false, '\n')
local dq_str = P('U')^-1 * delimited_range('"', '\\', true, false, '\n')
local triple_sq_str = "'''" * (any - "'''")^0 * P("'''")^-1
local triple_dq_str = '"""' * (any - '"""')^0 * P('"""')^-1
local raw_sq_str = P('u')^-1 * 'r' * delimited_range("'", nil, true) -- TODO: cannot end in single \
local raw_dq_str = P('U')^-1 * 'R' * delimited_range('"', nil, true) -- TODO: cannot end in single \
local string = token('string', triple_sq_str + triple_dq_str + sq_str + dq_str + raw_sq_str + raw_dq_str)

-- numbers
local dec = digit^1 * S('Ll')^-1
local bin = '0b' * S('01')^1 * ('_' * S('01')^1)^0
local oct = '0' * R('07')^1 * S('Ll')^-1
local integer = S('+-')^-1 * (bin + hex_num + oct + dec)
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif',
  'else', 'except', 'exec', 'finally', 'for', 'from', 'global', 'if', 'import',
  'in', 'is', 'lambda', 'not', 'or', 'pass', 'print', 'raise', 'return', 'try',
  'while', 'with', 'yield',
  -- descriptors/attr access
  '__get__', '__set__', '__delete__', '__slots__',
  -- class
  '__new__', '__init__', '__del__', '__repr__', '__str__', '__cmp__',
  '__index__', '__lt__', '__le__', '__gt__', '__ge__', '__eq__', '__ne__',
  '__hash__', '__nonzero__', '__getattr__', '__getattribute__', '__setattr__',
  '__delattr__', '__call__',
  -- operator
  '__add__', '__sub__', '__mul__', '__div__', '__floordiv__', '__mod__',
  '__divmod__', '__pow__', '__and__', '__xor__', '__or__', '__lshift__',
  '__rshift__', '__nonzero__', '__neg__', '__pos__', '__abs__', '__invert__',
  '__iadd__', '__isub__', '__imul__', '__idiv__', '__ifloordiv__', '__imod__',
  '__ipow__', '__iand__', '__ixor__', '__ior__', '__ilshift__', '__irshift__',
  -- conversions
  '__int__', '__long__', '__float__', '__complex__', '__oct__', '__hex__',
  '__coerce__',
  -- containers
  '__len__', '__getitem__', '__missing__', '__setitem__', '__delitem__',
  '__contains__', '__iter__', '__getslice__', '__setslice__', '__delslice__',
  -- module and class attribs
  '__doc__', '__name__', '__dict__', '__file__', '__path__', '__module__',
  '__bases__', '__class__', '__self__',
  -- stdlib/sys
  '__builtin__', '__future__', '__main__', '__import__', '__stdin__',
  '__stdout__', '__stderr__',
  -- other
  '__debug__', '__doc__', '__import__', '__name__'
}))

-- functions
local func = token('function', word_match(word_list{
  'abs', 'all', 'any', 'apply', 'basestring', 'bool', 'buffer', 'callable',
  'chr', 'classmethod', 'cmp', 'coerce', 'compile', 'complex', 'copyright',
  'credits', 'delattr', 'dict', 'dir', 'divmod', 'enumerate', 'eval',
  'execfile', 'exit', 'file', 'filter', 'float', 'frozenset', 'getattr',
  'globals', 'hasattr', 'hash', 'help', 'hex', 'id', 'input', 'int', 'intern',
  'isinstance', 'issubclass', 'iter', 'len', 'license', 'list', 'locals',
  'long', 'map', 'max', 'min', 'object', 'oct', 'open', 'ord', 'pow',
  'property', 'quit', 'range', 'raw_input', 'reduce', 'reload', 'repr',
  'reversed', 'round', 'set', 'setattr', 'slice', 'sorted', 'staticmethod',
  'str', 'sum', 'super', 'tuple', 'type', 'unichr', 'unicode', 'vars', 'xrange',
  'zip'
}))

-- constants
local constant = token('constant', word_match(word_list{
  'ArithmeticError', 'AssertionError', 'AttributeError', 'BaseException',
  'DeprecationWarning', 'EOFError', 'Ellipsis', 'EnvironmentError', 'Exception',
  'False', 'FloatingPointError', 'FutureWarning', 'GeneratorExit', 'IOError',
  'ImportError', 'ImportWarning', 'IndentationError', 'IndexError', 'KeyError',
  'KeyboardInterrupt', 'LookupError', 'MemoryError', 'NameError', 'None',
  'NotImplemented', 'NotImplementedError', 'OSError', 'OverflowError',
  'PendingDeprecationWarning', 'ReferenceError', 'RuntimeError',
  'RuntimeWarning', 'StandardError', 'StopIteration', 'SyntaxError',
  'SyntaxWarning', 'SystemError', 'SystemExit', 'TabError', 'True', 'TypeError',
  'UnboundLocalError', 'UnicodeDecodeError', 'UnicodeEncodeError',
  'UnicodeError', 'UnicodeTranslateError', 'UnicodeWarning', 'UserWarning',
  'ValueError', 'Warning', 'ZeroDivisionError'
}))

-- identifiers
local identifier = token('identifier', word)

-- decorators
local decorator = token('decorator', #P('@') * starts_line('@' * nonnewline^0))

-- operators
local operator = token('operator', S('!%^&*()[]{}-=+/|:;.,?<>~`'))

function LoadTokens()
  local python = python
  add_token(python, 'whitespace', ws)
  add_token(python, 'keyword', keyword)
  add_token(python, 'function', func)
  add_token(python, 'constant', constant)
  add_token(python, 'identifier', identifier)
  add_token(python, 'comment', comment)
  add_token(python, 'string', string)
  add_token(python, 'number', number)
  add_token(python, 'decorator', decorator)
  add_token(python, 'operator', operator)
  add_token(python, 'any_char', any_char)
end

function LoadStyles()
  add_style('decorator', style_preproc)
end
