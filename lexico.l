%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
LETTER [_a-zA-Z]
TIPO (int|float|char|boolean)

DELIM {ESPACO}+
NUM {DIGITO}+
FLOAT ({DIGITO}+"."{DIGITO}*)|({DIGITO}*"."{DIGITO}+)
VARIAVEL {LETTER}+({LETTER}|{DIGITO})*

%%

"\n"		{ linha++; }

{DELIM} 	{}

[+-]			{ return *yytext; }
[*/]			{ return *yytext; }
[()]            { return *yytext; }
[=]             { return *yytext; }

{FLOAT}     { yylval.label = yytext; return TK_FLOAT__; }
{NUM}		{ yylval.label = yytext; return TK_NUM; }
{TIPO}      { yylval.label = yytext; return TK_TIPO;  }
{VARIAVEL}  { yylval.label = yytext; return TK_VARIAVEL; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
