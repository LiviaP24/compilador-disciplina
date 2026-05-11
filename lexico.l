%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
LETTER [_a-zA-Z]
TIPO (int|float|char|bool)

DELIM {ESPACO}+
NUM {DIGITO}+
FLOAT ({DIGITO}+"."{DIGITO}*)|({DIGITO}*"."{DIGITO}+)
VARIAVEL {LETTER}+({LETTER}|{DIGITO})*
CHAR \'([^\\\']|\\.)\'
BOOL (true|false)

%%

"\n"		{ linha++; }
"&&"        { return TK_AND; }
"||"        { return TK_OR; }
"!"         { return TK_NOT; }
">"         { return TK_GT; }
"<"         { return TK_LT; }
"<="        { return TK_LE; }
">="        { return TK_GE; }
"=="        { return TK_EQ; }
"!="        { return TK_NE; }
"(int)"     { return TK_CAST_INT; }
"(float)"   { return TK_CAST_FLOAT; }

{DELIM} 	{}
"\r"        {}

[+-]			{ return *yytext; }
[*/]			{ return *yytext; }
[()]            { return *yytext; }
[=]             { return *yytext; }
[;]             { return *yytext; }

{BOOL}     { yylval.label = yytext; return TK_BOOL; }
{CHAR}      { yylval.label = yytext; return TK_CHAR; }
{FLOAT}     { yylval.label = yytext; return TK_FLOAT__; }
{NUM}		{ yylval.label = yytext; return TK_NUM; }
{TIPO}      { yylval.label = yytext; return TK_TIPO;  }
{VARIAVEL}  { yylval.label = yytext; return TK_VARIAVEL; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
