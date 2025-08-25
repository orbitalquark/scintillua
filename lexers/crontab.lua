-- Copyright 2025 Stepan Klokocka. See LICENSE.
-- Crontab LPeg lexer.

local lexer = require('lexer')
local P, S, R = lpeg.P, lpeg.S, lpeg.R

local lex = lexer.new(..., {no_user_word_lists = true})

-- Define basic patterns
local space = S(' \t')
local newline = P('\r\n') + P('\n') + P('\r')
local digit = R('09')
local alpha = R('az', 'AZ')
local alnum = alpha + digit

-- Whitespace
lex:add_rule('whitespace', lexer.token(lexer.WHITESPACE, space^1))

-- Comments
lex:add_rule('comment', lexer.token(lexer.COMMENT, lexer.to_eol('#')))

-- Numbers (field-specific)
lex:add_rule('minute', lexer.token('minute', digit^1))
lex:add_rule('hour', lexer.token('hour', digit^1))  
lex:add_rule('dom', lexer.token('dom', digit^1))     -- day of month
lex:add_rule('month_num', lexer.token('month_num', digit^1))
lex:add_rule('dow_num', lexer.token('dow_num', digit^1))   -- day of week
lex:add_rule('number', lexer.token(lexer.NUMBER, digit^1))

-- Special time strings
local special_times = lexer.word_match{
  '@yearly', '@annually', '@monthly', '@weekly', '@daily', '@midnight', '@hourly', '@reboot'
}
lex:add_rule('special_time', lexer.token(lexer.KEYWORD, special_times))

-- Month names  
local month_names = lexer.word_match{
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
}
lex:add_rule('month_name', lexer.token(lexer.KEYWORD, month_names))

-- Day names
local day_names = lexer.word_match{
  'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'
}
lex:add_rule('day_name', lexer.token(lexer.KEYWORD, day_names))

-- Cron operators
lex:add_rule('operator', lexer.token(lexer.OPERATOR, S('*,-/?')))

-- Environment variables
lex:add_rule('environment', lexer.token('environment', alpha * (alnum + P('_'))^0 * P('=') * (P(1) - newline)^0))

-- Commands (everything after time fields on a line)
lex:add_rule('command', lexer.token('command', alpha * (P(1) - space - newline)^0))

-- Strings
lex:add_rule('string', lexer.token(lexer.STRING, lexer.range("'") + lexer.range('"')))

-- Identifiers
lex:add_rule('identifier', lexer.token(lexer.IDENTIFIER, alpha * (alnum + S('_.-'))^0))

-- Default
lex:add_rule('default', lexer.token(lexer.DEFAULT, P(1)))

-- Add custom styles for cron fields (new format)
lex:add_style('minute', lexer.styles.number .. {color = 0xFF6B35})      -- Orange
lex:add_style('hour', lexer.styles.number .. {color = 0x4ECDC4})        -- Teal
lex:add_style('dom', lexer.styles.number .. {color = 0x45B7D1})         -- Blue
lex:add_style('month_num', lexer.styles.number .. {color = 0x96CEB4})   -- Green
lex:add_style('dow_num', lexer.styles.number .. {color = 0xFFEAA7})     -- Yellow
lex:add_style('environment', lexer.styles.variable .. {color = 0x9B59B6}) -- Purple
lex:add_style('command', lexer.styles['function'] .. {color = 0xE67E22})  -- Orange

-- Add folding points (fold comment blocks)
lex:add_fold_point(lexer.COMMENT, '#', newline)

return lex