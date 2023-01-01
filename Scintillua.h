// Copyright 2006-2023 Mitchell. See LICENSE.
// Include file for directly (statically) compiling Scintillua into a Scintilla-based application.

#ifndef SCINTILLUA_H
#define SCINTILLUA_H

#define SCLUA_DETECT 1

#ifdef __cplusplus
#include "ILexer.h"
#define ILEXER5 Scintilla::ILexer5
extern "C" {
#else
#define ILEXER5 void
#endif

const char *GetLibraryPropertyNames();
void SetLibraryProperty(const char *key, const char *value);
const char *GetNameSpace();
ILEXER5 *CreateLexer(const char *name);
const char *GetCreateLexerError();

#ifdef __cplusplus
}
#endif

#endif
