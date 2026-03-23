-- Arduino LPeg lexer.
-- Reference: https://docs.arduino.cc/language-reference/

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B
local lex = lexer.new(..., {inherit = lexer.load('c')})

-- Modify to allow builtins to be highlighted even as class members
local non_member = -(B('.') + B('->') + B('::'))
local builtin_func = lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN))
local func = lex:tag(lexer.FUNCTION, lexer.word)
local method = (B('.') + B('->')) * lex:tag(lexer.FUNCTION_METHOD, lexer.word)
lex:modify_rule('function', ((builtin_func) * non_member + method + func) * #(lexer.space^0 * '('))

lex:modify_rule('constants', lex:get_rule('constants') +
	lex:tag(lexer.VARIABLE_BUILTIN, lex:word_match(lexer.VARIABLE_BUILTIN)))

lex:set_word_list(lexer.KEYWORD, {
	-- Additional C++ Keywords (they highlight in Arduino IDE v1.8)
	'catch', 'class', 'const_cast',	'delete', 'dynamic_cast', 'explicit', 'export', 'friend',
	'mutable', 'namespace', 'new', 'operator', 'private', 'protected', 'public',
	'reinterpret_cast', 'static_cast', 'template', 'this', 'throw', 'try',
	'typeid', 'typename', 'using', 'virtual',
	'and', 'not', 'or', 'xor', 	-- Operators
	'final', 'override', -- C++11.
	'PROGMEM' -- Arduino
}, true)

lex:set_word_list(lexer.TYPE, {
	-- Additional C++ Types (they highlight in Arduino IDE v1.8)
	'wchar_t', --
	'char16_t', 'char32_t', -- C++11
	-- <cstddef>
	'byte', -- C++17
	-- Arduino
	'word', 'String'
}, true)

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
	'abs', 'constrain', 'map', 'max', 'min', 'pow', 'sq', 'exp', 'bit',
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


lex:set_word_list(lexer.CONSTANT_BUILTIN,
	'HIGH LOW INPUT INPUT_PULLUP OUTPUT LED_BUILTIN', true)

lex:set_word_list(lexer.VARIABLE_BUILTIN, {
	'EEPROM', 'SPI', 'Wire', 'Serial', 'Mouse', 'Keyboard',	'WiFi', 'BLE',
	'LiquidCrystal', 'lcd'
})

lexer.property['scintillua.comment'] = '//'

return lex
