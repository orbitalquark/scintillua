-- Nix LPEG lexer.
-- Written by Samuel Marquis.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN)))

-- Constants.
lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Strings.
local str = lexer.range('"', true)
local ml_str = lexer.range("''", false)
lex:add_rule('string', lex:tag(lexer.STRING, str + ml_str))

-- Paths.
local path_char = lexer.alnum + S('_-.+')
local path_seg = ('/' * path_char^1)
local path = P('~')^-1 * path_char^0 * path_seg^1 * lpeg.P('/')^-1
lex:add_rule('path', lex:tag(lexer.LINK, path))

-- URIs.
local uri_char = lexer.alnum + S("%/?:@&=+$,-_.!~*'")
local uri = lexer.alpha * (lexer.alnum + S('+-.'))^0 * ':' * uri_char^1
lex:add_rule('uri', lex:tag(lexer.LINK, uri))

-- Angle-bracket paths.
local spath = '<' * path_char^1 * path_seg^0 * '>'
lex:add_rule('spath', lex:tag(lexer.LINK, spath))

-- Identifiers.
local id = (lexer.alpha + '_') * (lexer.alnum + S('_-'))^0
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, id))

-- Comments.
local line_comment = lexer.to_eol('#', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
local l_ops = P('&&') + P('||') + P('->') + P('//') + P('++')
local s_ops = S('?+-.*/!<>=,;:()[]{}')
lex:add_rule('operator', lex:tag(lexer.OPERATOR, l_ops + s_ops))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
	'if', 'then', 'else', 'assert', 'with',
	'let', 'in', 'rec', 'inherit', 'or', '...',
})

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
	-- Directly accessible.
	'builtins', 'true', 'false', 'null',
	-- Accessible via the global `builtins` object.
	'currentSystem', 'currentTime', 'langVersion',
	'nixPath', 'nixVersion', 'storeDir',
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
	-- Directly accessible.
	'derivation', 'import', 'abort', 'throw',
	-- Accessible via the global `builtins` object.
	'add', 'all', 'any', 'attrNames', 'attrValues', 'baseNameOf', 'bitAnd',
	'bitOr', 'bitXor', 'break', 'catAttrs', 'ceil', 'compareVersions',
	'concatLists', 'concatMap', 'concatStringsSep', 'deepSeq', 'dirOf',
	'div', 'elem', 'elemAt', 'fetchClosure', 'fetchGit', 'fetchTarball',
	'fetchurl', 'filter', 'filterSource', 'findFile', 'flakeRefToString',
	'floor', "foldl'", -- It actually is called `foldl'`
	'fromJSON', 'fromTOML', 'functionArgs', 'genList', 'genericClosure',
	'getAttr', 'getContext', 'getEnv', 'getFlake', 'groupBy', 'hasAttr',
	'hasContext', 'hashFile', 'hashString', 'head', 'import',
	'intersectAttrs', 'isAttrs', 'isBool', 'isFloat', 'isFunction',
	'isInt', 'isList', 'isNull', 'isPath', 'isString', 'length',
	'lessThan', 'listToAttrs', 'map', 'mapAttrs', 'match', 'mul',
	'outputOf', 'parseDrvName', 'parseFlakeRef', 'partition', 'path',
	'pathExists', 'placeholder', 'readDir', 'readFile', 'readFileType',
	'removeAttrs', 'replaceStrings', 'seq', 'sort', 'split',
	'splitVersion', 'storePath', 'stringLength', 'sub', 'substring',
	'tail', 'throw', 'toFile', 'toJSON', 'toPath', 'toString', 'toXML',
	'trace', 'traceVerbose', 'tryEval', 'typeOf', 'zipAttrsWith'
})

lexer.property['scintillua.comment'] = '#'

return lex
