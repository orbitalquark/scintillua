-- Arduino LPeg lexer.
-- Reference: https://docs.arduino.cc/language-reference/

local lexer = lexer
local P, S = lpeg.P, lpeg.S
local lex = lexer.new(..., {inherit = lexer.load('cpp')})

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
	'setTimeout', 'getTimeout', 'flush'}, true)

lexer.property['scintillua.comment'] = '//'

return lex
