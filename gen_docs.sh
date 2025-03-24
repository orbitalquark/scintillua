#!/bin/bash
# Copyright 2025 Mitchell. See LICENSE.

# Generates Scintillua's documentation.
# Requires LDoc and Discount.

if [ "`uname`" = "Darwin" ]; then
	sed () {
		gsed "$@"
	}
fi

# Update API documentation, if possible. (This is unnecessary on end-user machines.)
if command -v ldoc &>/dev/null; then
	ldoc --filter docs.markdowndoc.ldoc lexers/lexer.lua > docs/api.md
fi

# Build html pages.
exit 0
pushd ../docs
bundle install
if [ -z "$LANG" ]; then export LANG="en_US.UTF-8"; fi
bundle exec jekyll build --baseurl "`pwd`" --quiet
cp _site/*.html .
cp -r _site/assets/css assets
rm -r _site
popd
