-- NSIS LPeg lexer
-- April 2010, Robert Gieseke
-- freely distributable under the same license as Textadept
-- based on NSIS 2.46 docs: http://nsis.sourceforge.net/Docs/

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments (4.1)
local line_comment = (';' * l.nonnewline^0) + ('#' * l.nonnewline^0)
local block_comment = '/*' * (l.any - '*/')^0 * '*/'
local comment = token('comment', line_comment + block_comment)

-- numbers
local number = token('number', l.integer)

-- strings
local sq_str = l.delimited_range("'", '$\\')
local dq_str = l.delimited_range('"', '$\\')
local ex_str = l.delimited_range('`', '$\\')
local string = token('string', sq_str + dq_str + ex_str)

-- variables (4.2)
local vars = word_match({
  '$0', '$1', '$2', '$3', '$4', '$5', '$6', '$7', '$8', '$9',
  '$R0', '$R1', '$R2', '$R3', '$R4', '$R5', '$R6', '$R7', '$R8', '$R9',
  '$INSTDIR', '$OUTDIR', '$CMDLINE', '$LANGUAGE',
  'Var', '/GLOBAL'
}, '$/')
local variable = token('variable', vars + ('$' * l.word))

-- constants (4.2.3)
local constant = token('constant', word_match({
  '$PROGRAMFILES', '$PROGRAMFILES32', '$PROGRAMFILES64',
  '$COMMONFILES', '$COMMONFILES32', '$COMMONFILES64',
  '$DESKTOP', '$EXEDIR', '$EXEFILE', '$EXEPATH', '${NSISDIR}', '$WINDIR',
  '$SYSDIR', '$TEMP', '$STARTMENU', '$SMPROGRAMS', '$SMSTARTUP',
  '$QUICKLAUNCH','$DOCUMENTS', '$SENDTO', '$RECENT', '$FAVORITES', '$MUSIC',
  '$PICTURES', '$VIDEOS', '$NETHOOD', '$FONTS', '$TEMPLATES', '$APPDATA',
  '$LOCALAPPDATA', '$PRINTHOOD', '$INTERNET_CACHE', '$COOKIES', '$HISTORY',
  '$PROFILE', '$ADMINTOOLS', '$RESOURCES', '$RESOURCES_LOCALIZED',
  '$CDBURN_AREA', '$HWNDPARENT', '$PLUGINSDIR',
}, '$_{}'))
-- TODO? Constants used in strings: $$ $\r $\n $\t

-- labels (4.3)
local label = token('label', l.word * ':')

-- keywords
local keyword = token('keyword', word_match({
-- Pages (4.5)
  'Page', 'UninstPage', 'PageEx', 'PageEnd', 'PageExEnd',
-- Section commands (4.6)
  'AddSize', 'Section', 'SectionEnd', 'SectionIn', 'SectionGroup',
  'SectionGroupEnd',
-- Functions (4.7)
  'Function', 'FunctionEnd',
-- Callbacks (4.7.2)
  '.onGUIInit', '.onInit', '.onInstFailed', '.onInstSuccess', '.onGUIEnd',
  '.onMouseOverSection', '.onRebootFailed', '.onSelChange', '.onUserAbort',
  '.onVerifyInstDir', 'un.onGUIInit', 'un.onInit', 'un.onUninstFailed',
  'un.onUninstSuccess', 'un.onGUIEnd', 'un.onRebootFailed', 'un.onSelChange',
  'un.onUserAbort',
-- General Attributes (4.8.1)
  'AddBrandingImage', 'AllowRootDirInstall', 'AutoCloseWindow', 'BGFont',
  'BGFont', 'BrandingText', '/TRIMLEFT', '/TRIMRIGHT', '/TRIMCENTER', 'Caption',
  'ChangeUI', 'CheckBitmap', 'CompletedText', 'ComponentText', 'CRCCheck',
  'DetailsButtonText', 'DirText', 'DirVar', 'DirVerify', 'FileErrorText',
  'Icon', 'InstallButtonText', 'InstallColors', 'InstallDir',
  'InstallDirRegKey', 'InstProgressFlags', 'InstType', 'LicenseBkColor',
  'LicenseData', 'LicenseForceSelection', 'LicenseText', 'MiscButtonText',
  'Name', 'OutFile', 'RequestExecutionLevel', 'SetFont', 'ShowInstDetails',
  'ShowUninstDetails', 'SilentInstall', 'SilentUnInstall', 'SpaceTexts',
  'SubCaption', 'UninstallButtonText', 'UninstallCaption', 'UninstallIcon',
  'UninstallSubCaption', 'UninstallText', 'WindowIcon', 'XPStyle', 'admin',
  'auto', 'bottom', 'checkbox', 'false', 'force', 'height', 'hide', 'highest',
  'leave', 'left', 'nevershow', 'none', 'normal', 'off', 'on', 'radiobuttons',
  'right', 'show', 'silent', 'silentlog', 'top', 'true', 'user', 'width',
-- Compiler Flags (4.8.2)
  'AllowSkipFiles', 'FileBufSize', 'SetCompress', 'SetCompressor',
  '/SOLID', '/FINAL', 'zlib', 'bzip2', 'lzma', 'SetCompressorDictSize',
  'SetDatablockOptimize', 'SetDateSave', 'SetOverwrite', 'ifnewer', 'ifdiff',
  'lastused', 'try',
-- Version Information (4.8.3)
  'VIAddVersionKey', 'VIProductVersion', '/LANG',
  'ProductName', 'Comments', 'CompanyName', 'LegalCopyright', 'FileDescription',
  'FileVersion', 'ProductVersion', 'InternalName', 'LegalTrademarks',
  'OriginalFilename', 'PrivateBuild', 'SpecialBuild',
-- Basic Instructions (4.9.1)
  'Delete', '/REBOOTOK', 'Exec', 'ExecShell', 'ExecShell', 'File', '/nonfatal',
  'Rename', 'ReserveFile', 'RMDir', 'SetOutPath',
-- Registry, INI, File Instructions (4.9.2)
  'DeleteINISec', 'DeleteINIStr', 'DeleteRegKey', '/ifempty',
  'DeleteRegValue', 'EnumRegKey', 'EnumRegValue', 'ExpandEnvStrings',
  'FlushINI', 'ReadEnvStr', 'ReadINIStr', 'ReadRegDWORD', 'ReadRegStr',
  'WriteINIStr', 'WriteRegBin', 'WriteRegDWORD', 'WriteRegStr',
  'WriteRegExpandStr', 'HKCR', 'HKEY_CLASSES_ROOT', 'HKLM', 'HKEY_LOCAL_MACHINE',
  'HKCU', 'HKEY_CURRENT_USER', 'HKU', 'HKEY_USERS', 'HKCC',
  'HKEY_CURRENT_CONFIG', 'HKDD', 'HKEY_DYN_DATA', 'HKPD',
  'HKEY_PERFORMANCE_DATA', 'SHCTX', 'SHELL_CONTEXT',

-- General Purpose Instructions (4.9.3)
  'CallInstDLL', 'CopyFiles',
  '/SILENT', '/FILESONLY', 'CreateDirectory', 'CreateShortCut', 'GetDLLVersion',
  'GetDLLVersionLocal', 'GetFileTime', 'GetFileTimeLocal', 'GetFullPathName',
  '/SHORT', 'GetTempFileName', 'SearchPath', 'SetFileAttributes', 'RegDLL',
  'UnRegDLL',
-- Flow Control Instructions (4.9.4)
  'Abort', 'Call', 'ClearErrors', 'GetCurrentAddress', 'GetFunctionAddress',
  'GetLabelAddress', 'Goto', 'IfAbort', 'IfErrors', 'IfFileExists',
  'IfRebootFlag', 'IfSilent', 'IntCmp', 'IntCmpU', 'MessageBox', 'MB_OK',
  'MB_OKCANCEL', 'MB_ABORTRETRYIGNORE', 'MB_RETRYCANCEL', 'MB_YESNO',
  'MB_YESNOCANCEL', 'MB_ICONEXCLAMATION', 'MB_ICONINFORMATION',
  'MB_ICONQUESTION', 'MB_ICONSTOP', 'MB_USERICON', 'MB_TOPMOST',
  'MB_SETFOREGROUND', 'MB_RIGHT', 'MB_RTLREADING', 'MB_DEFBUTTON1',
  'MB_DEFBUTTON2', 'MB_DEFBUTTON3', 'MB_DEFBUTTON4', 'IDABORT', 'IDCANCEL',
  'IDIGNORE', 'IDNO', 'IDOK', 'IDRETRY', 'IDYES', 'Return', 'Quit', 'SetErrors',
  'StrCmp', 'StrCmpS',
-- File Instructions (4.9.5)
  'FileClose', 'FileOpen', 'FileRead', 'FileReadByte', 'FileSeek', 'FileWrite',
  'FileWriteByte', 'FindClose', 'FindFirst', 'FindNext',
-- Uninstaller Instructions (4.9.6)
  'WriteUninstaller',
-- Miscellaneous Instructions (4.9.7)
  'GetErrorLevel', 'GetInstDirError', 'InitPluginsDir', 'Nop', 'SetErrorLevel',
  'SetRegView', 'SetShellVarContext', 'all', 'current', 'Sleep',
-- String Manipulation Instructions (4.9.8)
  'StrCpy', 'StrLen',
-- Stack Support (4.9.9)
  'Exch', 'Pop', 'Push',
-- Integer Support (4.9.10)
  'IntFmt', 'IntOp',
-- Reboot Instructions (4.9.11)
  'Reboot', 'SetRebootFlag',
-- Install Logging Instructions (4.9.12)
  'LogSet', 'LogText',
-- Section Management (4.9.13)
  'SectionSetFlags', 'SectionGetFlags', 'SectionGetFlags',
  'SectionSetText', 'SectionGetText', 'SectionSetInstTypes',
  'SectionGetInstTypes', 'SectionSetSize', 'SectionGetSize', 'SetCurInstType',
  'GetCurInstType', 'InstTypeSetText', 'InstTypeGetText',
-- User Interface Instructions (4.9.14)
  'BringToFront', 'CreateFont', 'DetailPrint', 'EnableWindow', 'FindWindow',
  'GetDlgItem', 'HideWindow', 'IsWindow', 'LockWindow', 'SendMessage',
  'SetAutoClose', 'SetBrandingImage', 'SetDetailsView', 'SetDetailsPrint',
  'listonly','textonly', 'both', 'SetCtlColors', '/BRANDING', 'SetSilent',
  'ShowWindow',
-- Multiple Languages Instructions (4.9.15)
  'LoadLanguageFile', 'LangString', 'LicenseLangString',
-- Compile time commands (5)
  '!include', '!addincludedir', '!addplugindir', '!appendfile', '!cd',
  '!delfile', '!echo', '!error', '!execute', '!packhdr', '!system', '!tempfile',
  '!warning', '!verbose', '{__FILE__}', '{__LINE__}', '{__DATE__}',
  '{__TIME__}', '{__TIMESTAMP__}', '{NSIS_VERSION}', '!define', '!undef',
  '!ifdef', '!ifndef', '!if', '!ifmacrodef', '!ifmacrondef', '!else', '!endif',
  '!insertmacro', '!macro', '!macroend', '!searchparse', '!searchreplace',
}, '/!.{}_'))

-- operators
local operator = token('operator', S('+-*/%|&^~!<>'))

-- labels
local label = token('label', l.word * ":")

-- identifiers
local identifier = token('identifier', l.word)

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'constant', constant },
  { 'variable', variable },
  { 'keyword', keyword },
  { 'number', number },
  { 'operator', operator },
  { 'label', label },
  { 'identifier', identifier },
  { 'any_char', l.any_char },
}

local style_bold = l.style { bold = true }
_tokenstyles = {
  { 'label', style_bold }
}
