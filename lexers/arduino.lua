-- Arduino LPeg lexer.
-- Reference: https://docs.arduino.cc/language-reference/

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B
local lex = lexer.new(..., {inherit = lexer.load('cpp')})

-- Modify to allow builtins to be highlighted even as class members
local non_member = -(B('.') + B('->') + B('::'))
local builtin_func = lex:tag(lexer.FUNCTION_BUILTIN,
	P('std::')^-1 * lex:word_match(lexer.FUNCTION_BUILTIN))
local stl_func = lex:tag(lexer.FUNCTION_BUILTIN .. '.stl',
	'std::' * lex:word_match(lexer.FUNCTION_BUILTIN .. '.stl'))
local func = lex:tag(lexer.FUNCTION, lexer.word)
local method = (B('.') + B('->')) * lex:tag(lexer.FUNCTION_METHOD, lexer.word)
lex:modify_rule('function',
	((stl_func + builtin_func) * non_member + method + func) * #(lexer.space^0 * '('))

lex:set_word_list(lexer.TYPE, 'word String', true)

lex:set_word_list(lexer.CONSTANT_BUILTIN,
	'HIGH LOW INPUT INPUT_PULLUP OUTPUT LED_BUILTIN', true)

lex:set_word_list(lexer.KEYWORD, 'PROGMEM', true)

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
	-- I/O
	'digitalRead', 'digitalWrite', 'pinMode',
	'analogRead', 'analogReadResolution', 'analogReference',
	'analogWrite', 'analogWriteResolution',
	-- Adv I/O
	'noTone', 'pulseIn', 'pulseInLong', 'shiftIn', 'shiftOut', 'tone',
	-- Time
	'delay', 'delayMicroseconds', 'micros', 'millis',
	-- Maths (most are covered by cmath, just adding the missing ones)
	'constrain', 'map', 'max', 'min', 'sq',
	-- Characters
	'isAlpha', 'isAlphaNumeric', 'isAscii', 'isControl', 'isDigit', 'isGraph',
	'isHexadecimalDigit', 'isLowerCase', 'isPrintable', 'isPunct', 'isSpace',
	'isUpperCase', 'isWhitespace',
	-- Random
	'random', 'randomSeed',
	-- Bits/Bytes
	'bit', 'bitClear', 'bitRead', 'bitSet', 'bitWrite', 'highByte', 'lowByte',
	-- Interrupts
	'attachInterrupt', 'detachInterrupt', 'digitalPinToInterrupt',
	'interrupts', 'noInterrupts',
	-- Abstract Print Class (members used in most libraries e.g. SPI, LCD...)
	'write', 'print', 'println',
	-- Abstract Stream Class (members used in most libraries e.g. SPI, LCD...)
	'available', 'read', 'peek', 'readBytes', 'readBytesUntil', 'readString',
    'readStringUntil', 'find', 'findUntil', 'parseInt', 'parseFloat',
	'setTimeout', 'getTimeout', 'flush',
	'begin', 'end' -- Not in spec but common
	}, true)

lexer.property['scintillua.comment'] = '//'

return lex
