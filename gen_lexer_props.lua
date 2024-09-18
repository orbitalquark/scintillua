#!/usr/bin/lua

local format, concat = string.format, table.concat

-- Do not glob these files. (e.g. *.foo)
local noglobs = {
	Dockerfile = true, GNUmakefile = true, Makefile = true, makefile = true, Rakefile = true,
	['Rout.save'] = true, ['Rout.fail'] = true, fstab = true, ['meson.build'] = true
}

local alt_name = {actionscript = 'flash', javascript = 'js', python = 'py', ruby = 'rb'}

-- Process file patterns and lexer definitions.
local f = io.open('lexers/lexer.lua')
local definitions = f:read('*all'):match('local extensions = (%b{})')
f:close()

local output = {'# Lexer definitions ('}
local function append(lang, exts, lexer)
	output[#output + 1] = format('file.patterns.%s=%s', lang, concat(exts, ';'))
	output[#output + 1] = format('lexer.$(file.patterns.%s)=scintillua.%s', lang, lexer)
	output[#output + 1] = format('keywords.$(file.patterns.%s)=scintillua', lang)
	for i = 2, 9 do
		output[#output + 1] = format('keywords%d.$(file.patterns.%s)=scintillua', i, lang)
	end
end
local lexer, ext, last_lexer
local exts = {}
for ext, lexer in definitions:gmatch("([^%s,'%]-]+)'?%]?%s*=%s*'([%w_]+)'") do
	if lexer ~= last_lexer and #exts > 0 then
		append(alt_name[last_lexer] or last_lexer, exts, last_lexer)
		exts = {}
	end
	exts[#exts + 1] = not noglobs[ext] and '*.' .. ext or ext
	last_lexer = lexer
end
append(alt_name[last_lexer] or last_lexer, exts, last_lexer)
output[#output + 1] = '# )'

-- Write to lpeg.properties.
f = io.open('scintillua.properties')
local text = f:read('*all')
text = text:gsub('# Lexer definitions %b()', table.concat(output, '\n'), 1)
f:close()
f = io.open('scintillua.properties', 'wb')
f:write(text)
f:close()
