#!/bin/bash

cd scintilla
hg diff > a.patch
sed -i -e 's/^\([+-]\{3\}\) [ab]/\1 scintilla/g;' a.patch
cd ../
cd scite
hg diff > a.patch
sed -i -e 's/^\([+-]\{3\}\) [ab]/\1 scite/g;' a.patch
cd ../
cat scintilla/a.patch scite/a.patch > scintillua.patch
rm scintilla/a.patch scite/a.patch
