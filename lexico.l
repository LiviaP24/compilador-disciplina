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

%%

"\n"		{ linha++; }
"&&"        { return TK_AND; }
"||"        { return TK_OR; }
"!"         { return TK_NOT; }
">="  { return TK_GE; }
"<="  { return TK_LE; }
"=="  { return TK_EQ; }
"!="  { return TK_NE; }
">"   { return TK_GT; }
"<"   { return TK_LT; }


\'([^\\\']|\\.)\'   { yylval.label = yytext; return TK_CHAR; }

{DELIM} 	{}

{FLOAT}     { yylval.label = yytext; return TK_FLOAT__; }
{NUM}		{ yylval.label = yytext; return TK_NUM; }
{TIPO}      { yylval.label = yytext; return TK_TIPO;  }
"true"      { yylval.label = yytext; return TK_BOOL; }
"false"     { yylval.label = yytext; return TK_BOOL; }
[+-]			{ return *yytext; }
[*/]			{ return *yytext; }
[()]            { return *yytext; }
[=]             { return *yytext; }
{VARIAVEL}  { yylval.label = yytext; return TK_VARIAVEL; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
