# Scintillua

## Overview

Scintillua adds dynamic [Lua][] [LPeg][] lexers to [Scintilla][]. It is the
quickest way to add new or customized syntax highlighting and code folding for
programming languages to any Scintilla-based text editor or IDE. Scintillua was
designed to be dropped into or compiled with any Scintilla environment.

[Lua]: http://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla]: http://scintilla.org

## Features

* Drop-in installation in most Scintilla environments -- no modifications to
  Scintilla are necessary.
* Support for over 80 programming languages.
* Easy lexer embedding for multi-language lexers.
* Universal color themes.
* Comparable speed to native Scintilla lexers.

## Requirements

Scintillua only requires Scintilla 2.25 or greater. Lua and LPeg have been
pre-compiled into the external lexer and you can download their source files
using the links above should you choose to compile Scintillua directly into a
Scintilla-based application.

## Download

Download Scintillua from the project's [download page][].

[download page]: http://foicica.com/scintillua/download

## Installation and Usage

Scintillua comes with a manual and API documentation in the `doc/` directory.
They are also available [online][].

[online]: http://foicica.com/scintillua

## Contact

Contact me by email: mitchell.att.foicica.com.

There is also a [mailing list][].

[mailing list]: http://foicica.com/lists

## Donate

Your donations are very much appreciated and go towards web server maintainence
and hosting for Scintillua, its source code repository, mailing list, etc.

<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="3165962">
<input type="image" src="https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="">
<img alt="Donate" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
