%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
LETTER [_a-zA-Z]
TIPO (int|float|char|bool|string)

DELIM {ESPACO}+
NUM {DIGITO}+
FLOAT ({DIGITO}+"."{DIGITO}*)|({DIGITO}*"."{DIGITO}+)
VARIAVEL {LETTER}+({LETTER}|{DIGITO})*
CHAR \'([^\\\']|\\.)*\'
BOOL (true|false)
STRING \"([^\\\"]|\\.)*\"

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

"++"        { return TK_INC; }
"--"        { return TK_DEC; }
"+="        { return TK_PLUS_EQ; }
"-="        { return TK_MINUS_EQ; }
"*="        { return TK_STAR_EQ; }
"/="        { return TK_SLASH_EQ; }
[+-]		{ return *yytext; }
[*/]		{ return *yytext; }
[()]            { return *yytext; }
[=]             { return *yytext; }
[;,:]           { return *yytext; }
[{}]            { return *yytext; }
[\[\]]          { return *yytext; }

"scanf"     { return TK_SCANF; }
"printf"    { return TK_PRINTF; }

"if"        { return TK_IF; }
"else"      { return TK_ELSE; }
"while"     { return TK_WHILE; }
"do"        { return TK_DO; }
"for"       { return TK_FOR; }
"switch"    { return TK_SWITCH; }
"case"      { return TK_CASE; }
"default"   { return TK_DEFAULT; }
"break"     { return TK_BREAK; }
"continue"  { return TK_CONTINUE; }
"return"    { return TK_RETURN; }
"void"      { return TK_VOID; }

{BOOL}     { yylval.label = yytext; return TK_BOOL; }
{CHAR}      { yylval.label = yytext; return TK_CHAR; }
{STRING}    { yylval.label = yytext; return TK_STRING; }
{FLOAT}     { yylval.label = yytext; return TK_FLOAT__; }
{NUM}		{ yylval.label = yytext; return TK_NUM; }
{TIPO}      { yylval.label = yytext; return TK_TIPO;  }
{VARIAVEL}  { yylval.label = yytext; return TK_VARIAVEL; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
