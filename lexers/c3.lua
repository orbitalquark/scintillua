-- Copyright 2006-2025 Mitchell. See LICENSE.
-- C3 LPeg lexer.

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(..., { inherit = lexer.load('c') })

-- Comments.
local line_comment = lexer.to_eol('//', true) + lexer.to_eol('#!', true)
local ws = S(' \t')^0
local block_comment = lexer.range('/*', '*/') + lexer.range('<*', '*>') 
    + lexer.range('$if' * ws * '0' * lexer.space, '$endif')
local comments = lex:tag(lexer.COMMENT, line_comment + block_comment)
lex:add_rule('comment', comments)

-- Preprocessor.
local preproc = lex:tag(lexer.PREPROCESSOR, '$' * ws * lex:word_match(lexer.PREPROCESSOR))
lex:add_rule('preprocessor', preproc)

-- Attributes. Note that this replace the existing C attributes rules since it is not needed
local attrs = lex:tag(lexer.ATTRIBUTE, '@' * ws * lex:word_match(lexer.ATTRIBUTE))
lex:add_rule('attribute', attrs)

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, '$if', '$endif')
lex:add_fold_point(lexer.PREPROCESSOR, '$for', '$endfor')
lex:add_fold_point(lexer.PREPROCESSOR, '$foreach', '$endforeach')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '<*', '*>')

-- Word lists. 
--- I could inherit from the C one for the keywords but everything's here so this is fine (probably)
--- The wordlist that really benefits from inheritance is FUNCTION_BUILTIN and PREPROCESSOR
lex:set_word_list(lexer.KEYWORD, {
    'inline', 'alias', 'default', 'do', 'else', 'var', 'while', 'nextcase', 'switch', 'fn', 'local', 'attrdef', 'if', 'foreach_r', 'extern', 'foreach', 'import', 'macro', 'for', 'case', 'catch', 'continue', 'try', 'break', 'typedef', 'return', 'const', 'module', 'typeid', 'defer', 'assert', 'asm', 'static', 'tlocal', -- Base keywords
    'alignof', 'associated', 'elements', 'extnameof', 'inf', 'inner', 'kindof', 'len', 'max', 'membersof', 'methodsof', 'min', 'nan', 'nameof', 'names', 'paramsof', 'parentof', 'qnameof','returns', 'sizeof', 'typeid', 'values', -- 0.7.x reflection syntax
})

lex:set_word_list(lexer.TYPE, {
    'isz', 'iptr', 'uint128', 'double', 'float', 'fault', 'struct', 'int128', 'ulong', 'uptr', 'true', 'fn', 'void', 'union', 'float16', 'bitstruct', 'false', 'enum', 'bool', 'ichar', 'int', 'float128', 'any', 'char', 'null', 'usz', 'long', 'short', 'ushort', 'uint', -- Base types
    'CChar', 'CShort', 'CUShort', 'CInt', 'CUInt', 'CLong', 'CULong', 'CLongLong', 'CULongLoug', 'CLongDouble', -- C compatibility types provided by C3
})

-- Inherit everything from the C lexer for these builtins
lex:set_word_list(lexer.FUNCTION_BUILTIN, {}, true)

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
    '$$BENCHMARK_FNS', '$$FILEPATH', '$$BENCHMARK_NAMES', '$$LINE_RAW', '$$MODULE', '$$TEST_FNS', '$$TEST_NAMES', '$$TIME', '$$LINE', '$$FUNC', '$$FUNCTION', '$$DATE', '$$FILE',
})

lex:set_word_list(lexer.PREPROCESSOR, {
    'evaltype', 'qnameof', 'sizeof', 'vasplat', 'alignof', 'for', 'echo', 'vatype', 'include', 'endforeach', 'exec', 'switch', 'extnameof', 'nameof', 'vacount', 'vaconst', 'vaarg', 'offsetof', 'endfor', 'embed', 'default', 'endswitch', 'assert', 'stringify', 'foreach', 'typefrom', 'typeof', 'eval', 'case', 'vaexpr',
    },
    true)

lex:set_word_list(lexer.ATTRIBUTE, {
    'builtin', 'cdecl', 'maydiscard', 'reflect', 'obfuscate', 'align', 'priority', 'weak', 'bigendian', 'noinline', 'noreturn', 'winmain', 'nostrip', 'test', 'operator', 'overlap', 'deprecated', 'interface', 'littleendian', 'packed', 'pure', 'local', 'benchmark', 'mustinit', 'naked', 'private', 'public', 'dynamic', 'export', 'section', 'stdcall', 'inline', 'cname', 'nodiscard', 'unused', 'noinit', 'extname', 'wasm', 'used', 'veccall', -- In language reference
    'param', 'ensure', 'require', -- Specifically for function doc comments/contracts
})

lexer.property['scintillua.comment'] = '//'

return lex
