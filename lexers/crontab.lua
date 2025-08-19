-- Copyright 2025 Stepan Klokocka. See LICENSE.
-- Crontab LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local lex = lexer.new('crontab')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
local digit = R('09')
local number = digit^1
lex:add_rule('number', token(lexer.NUMBER, number))

-- Cron operators.
local operators = S('*,-/?')
lex:add_rule('operator', token(lexer.OPERATOR, operators))

-- Special time strings.
local special_times = word_match{
  '@yearly', '@annually', '@monthly', '@weekly', '@daily', '@midnight', '@hourly', '@reboot'
}
lex:add_rule('special_time', token('special_time', special_times))

-- Month names (can be used in month field).
local month_names = word_match{
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  'january', 'february', 'march', 'april', 'may', 'june',
  'july', 'august', 'september', 'october', 'november', 'december'
}

-- Day names (can be used in day-of-week field).
local day_names = word_match{
  'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat',
  'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
}

-- Month and day names.
lex:add_rule('month_name', token('month_name', month_names))
lex:add_rule('day_name', token('day_name', day_names))

-- Environment variables (VAR=value).
local env_var = lexer.alpha * (lexer.alnum + '_')^0 * '=' * lexer.nonnewline^0
lex:add_rule('environment', token('environment', env_var))

-- Strings (quoted).
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Commands (everything after the 5 time fields).
-- This is a complex rule that matches after whitespace-separated fields.
local field = (number + operators + month_names + day_names + lexer.alpha^1)
local time_spec = special_times + (field * (lexer.space^1 * field)^4)
local command_start = time_spec * lexer.space^1
local command = lexer.nonnewline^1

-- Add a rule for the entire cron line structure.
local cron_line = P{
  'line',
  line = V('special_line') + V('env_line') + V('cron_entry_line') + V('comment_line'),
  
  special_line = token('special_time', special_times) * 
                lexer.space^1 * 
                token('command', lexer.nonnewline^0),
                
  env_line = token('environment', lexer.alpha * (lexer.alnum + '_')^0) *
            token(lexer.OPERATOR, '=') *
            token('env_value', lexer.nonnewline^0),
            
  comment_line = token(lexer.COMMENT, '#' * lexer.nonnewline^0),
  
  cron_entry_line = V('minute_field') * lexer.space^1 *
                   V('hour_field') * lexer.space^1 *
                   V('dom_field') * lexer.space^1 *
                   V('month_field') * lexer.space^1 *
                   V('dow_field') * lexer.space^1 *
                   token('command', lexer.nonnewline^0),
                   
  minute_field = token('minute', V('field_content')),
  hour_field = token('hour', V('field_content')),
  dom_field = token('dom', V('field_content')),
  month_field = token('month', V('field_content') + month_names),
  dow_field = token('dow', V('field_content') + day_names),
  
  field_content = (number + operators + '?')^1
}

-- Simplified approach - use individual rules and rely on order.
-- Identifiers (for unrecognized words that might be part of commands).
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.alpha * (lexer.alnum + '_')^0))

-- Everything else (commands, paths, etc.).
lex:add_rule('default', token(lexer.DEFAULT, lexer.any))

-- Define token styles.
local styles = {
  special_time = lexer.STYLE_KEYWORD,
  environment = lexer.STYLE_VARIABLE,
  env_value = lexer.STYLE_STRING,
  month_name = lexer.STYLE_KEYWORD .. ',bold',
  day_name = lexer.STYLE_KEYWORD .. ',bold',
  command = lexer.STYLE_FUNCTION,
  minute = lexer.STYLE_NUMBER .. ',fore:#FF6B35',      -- Orange for minute
  hour = lexer.STYLE_NUMBER .. ',fore:#4ECDC4',        -- Teal for hour  
  dom = lexer.STYLE_NUMBER .. ',fore:#45B7D1',         -- Blue for day of month
  month = lexer.STYLE_NUMBER .. ',fore:#96CEB4',       -- Green for month
  dow = lexer.STYLE_NUMBER .. ',fore:#FFEAA7'          -- Yellow for day of week
}

-- Apply styles.
for token_name, style in pairs(styles) do
  lex:add_style(token_name, style)
end

-- Folding (minimal - just for readability).
-- Fold on blank lines to separate cron entries.
lex:add_fold_point(lexer.WHITESPACE, lexer.newline^2, '')

-- Word lists for autocompletion (commented out as they cause errors in some Scintillua versions).
-- If your Scintillua version supports word lists, uncomment these:
-- lex:set_word_list(lexer.KEYWORD, {
--   '@yearly', '@annually', '@monthly', '@weekly', '@daily', '@midnight', '@hourly', '@reboot'
-- })
-- lex:set_word_list('month', {
--   'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
-- })
-- lex:set_word_list('day', {
--   'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'
-- })

return lex