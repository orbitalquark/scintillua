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

# Copy README into index and update links.
sed -e 's/^\# [[:alpha:]]\+/## Introduction/;' -e \
	's|https://[[:alpha:]]\+\.github\.io/[[:alpha:]]\+/||;' README.md > docs/index.md

# Generate HTML from Markdown (docs/*.html from docs/*.md)
cd docs
for file in `ls *.md`; do
	cat _layouts/default.html | ./fill_layout.lua $file > `basename -s .md $file`.html
done
