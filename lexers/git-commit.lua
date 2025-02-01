-- git-commit
local lexer = lexer
local lex = lexer.new(...)

-- limiting function for commit hash
local function patn(pat, min, max)
	return -pat^(max + 1) * pat^min
end

-- characters allowed in summary
local c = lexer.nonnewline

-- limit summary line length to git.summary_length - default to 76 if unset
local summary = lpeg.P(function(s, i)
	
	-- assert that we're on the first line
	if lexer.line_from_position(i) > 1 then
		return false
	end

	local n = tonumber(lexer.property['git.summary_length'])
	if n == nil then
		n = 76
	end

	-- make sure the first character isn't a comment
	-- and is limited to git.summary_length
	local p = (c-lpeg.P('#'))*c^-(n-2)

	return lpeg.match(p, s, i)
end)

lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol(lexer.starts_line('#'))))
lex:add_rule('hash',    lex:tag(lexer.NUMBER,  patn(lpeg.R('09', 'af'), 7, 40)))
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lexer.starts_line(lex:word_match(lexer.KEYWORD))*':'))
lex:add_rule('summary', lex:tag(lexer.STRING,  lexer.starts_line(summary*(lpeg.P('\n')+c))))


-- Word lists.
lex:set_word_list(lexer.KEYWORD, [[
Acked-by
Co-authored-by
Reported-and-tested-by
Reported-by
Reviewed-by
Signed-off-by
Suggested-by
Tested-by
To
Cc
From
After
Before
]])

return lex
