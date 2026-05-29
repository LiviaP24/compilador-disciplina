	%{
	#include <iostream>
	#include <string>
	#include <map>
	#include <vector>

	#define YYSTYPE atributos

	using namespace std;

	int var_temp_qnt;
	int var_temp;
	int linha = 1;
	string var;
	string codigo_gerado;
	bool usa_string = false;
	int label_qnt = 0;

	vector<string> pilha_break;   // labels de break para loops e switch
	vector<string> pilha_inicio;  // labels de volta para loops (goto inicio)
	string g_switch_expr_temp = "";  // temporario da expressao do switch atual

	struct atributos
	{
		string label;
		string traducao;
		string tipo;
		bool is_literal = false;
	};

	struct variavel
	{
		string temp;
		string tipo;
		string valor;
	};

	vector<map<string, variavel>> pilha_escopos;

	// Tabela de tipos: chave "operacao:tipo1:tipo2", valor = resultado
	map<string, string> tab_tipos = {
		// Aritmetica (+, -, *, /)     tipo1     tipo2     resultado
		{"aritm:int:int",     "int"},
		{"aritm:int:float",   "float"},
		{"aritm:float:int",   "float"},
		{"aritm:float:float", "float"},
		// Relacional (>, <, >=, <=)   tipo1     tipo2     resultado
		{"relac:int:int",     "bool"},
		{"relac:int:float",   "bool"},
		{"relac:float:int",   "bool"},
		{"relac:float:float", "bool"},
		// Igualdade (==, !=)          tipo1     tipo2     resultado
		{"igual:int:int",     "bool"},
		{"igual:int:float",   "bool"},
		{"igual:float:int",   "bool"},
		{"igual:float:float", "bool"},
		{"igual:bool:bool",   "bool"},
		{"igual:char:char",   "bool"},
		// Logico (&&, ||, !)          tipo      resultado
		{"logico:bool:",      "bool"},
		// Atribuicao                  var       expr      resultado
		{"atrib:int:int",     "ok"},
		{"atrib:float:float", "ok"},
		{"atrib:bool:bool",   "ok"},
		{"atrib:char:char",   "ok"},
		{"atrib:float:int",   "promove"},
	};

	int yylex(void);
	void yyerror(string);
	string gentempcode();
	string genLabel();
	string genContaChars(string, string);
	string genMallocStr(string, string, string);
	void add_var(string, string, bool, string);
	string chave_temp();
	bool verificacao_tabela(string);
	variavel buscar_var(string);
	void entra_escopo();
	void sai_escopo();
	string checar_aritmetico(string t1, string t2);
	bool   checar_relacional(string t1, string t2);
	bool   checar_igualdade(string t1, string t2);
	bool   checar_logico(string t);
	string checar_atribuicao(string tv, string te);
	atributos converter_p_float(atributos e);
	atributos converter_p_int(atributos e);

	%}

	%token TK_NUM
	%token TK_FLOAT__
	%token TK_VARIAVEL
	%token TK_TIPO
	%token TK_BOOL TK_CHAR
	%token TK_AND TK_OR TK_NOT
	%token TK_GT TK_LT TK_GE TK_LE TK_EQ TK_NE
	%token TK_CAST_INT TK_CAST_FLOAT
	%token TK_PRINTF TK_SCANF TK_STRING
	%token TK_IF TK_ELSE TK_WHILE TK_DO TK_FOR
	%token TK_SWITCH TK_CASE TK_DEFAULT TK_BREAK

	// Resolve ambiguidade do dangling-else: else tem maior precedencia
	%nonassoc TK_THEN
	%nonassoc TK_ELSE

	%start S

	%left TK_OR
	%left TK_AND
	%right TK_NOT

	%nonassoc TK_GT TK_LT TK_GE TK_LE TK_EQ TK_NE

	%left '+''-'
	%left '*''/'
	%right UMINUS

	%%

	S 			: cmds
				{
					codigo_gerado = "/*Compilador FOCA*/\n"
									"#include <stdio.h>\n";
					if (usa_string) {
						codigo_gerado += "#include <stdlib.h>\n";
						codigo_gerado += "#include <string.h>\n";
					}
					codigo_gerado += "int main(void) {\n";
					
					codigo_gerado += var;

					codigo_gerado += "\n";
					
					codigo_gerado += $1.traducao;

					codigo_gerado += "\treturn 0;"
								"\n}\n";
				}
				;

	cmds		: cmds cmd
				{
				    $$.traducao = $1.traducao + $2.traducao;	
				}
				| cmd
				{
					 $$.traducao = $1.traducao;
				}
				;

	cmd			: E ';'
				{
					$$.traducao = $1.traducao;
				}
				| D ';'
				{
					$$.traducao = $1.traducao;
				}
				| BLOCO
				{
					$$.traducao = $1.traducao;
				}
				| TK_PRINTF '(' TK_STRING ')' ';'
				{
					// printf sem argumentos adicionais: printf("texto\n")
					$$.traducao = "\tprintf(" + $3.label + ");\n";
				}
				| TK_PRINTF '(' TK_STRING ',' printf_args ')' ';'
				{
					// printf com argumentos: printf("%d\n", expr)
					$$.traducao = $5.traducao + "\tprintf(" + $3.label + ", " + $5.label + ");\n";
				}
				| TK_SCANF '(' TK_STRING ')' ';'
				{
					// scanf sem argumentos: scanf("\n") — incomum mas valido
					$$.traducao = "\tscanf(" + $3.label + ");\n";
				}
				| TK_SCANF '(' TK_STRING ',' scanf_args ')' ';'
				{
					// scanf com argumentos: scanf("%d", n) ou scanf("%s", s) etc.
					// $5.traducao = pre-codigo (malloc 256 p/ strings)
					// $5.tipo     = pos-codigo (redimensiona strings apos scanf)
					$$.traducao = $5.traducao
					            + "\tscanf(" + $3.label + ", " + $5.label + ");\n"
					            + $5.tipo;
				}
				| TK_BREAK ';'
				{
					if (pilha_break.empty()) {
						yyerror("'break' fora de loop ou switch");
						exit(1);
					}
					$$.traducao = "\tgoto " + pilha_break.back() + ";\n";
				}
				| TK_IF '(' E ')' cmd %prec TK_THEN
				{
					string L_fim = genLabel();
					string t_neg = gentempcode(); add_var(t_neg, "int", true, t_neg);
					$$.traducao = $3.traducao
					           + "\t" + t_neg + " = !" + $3.label + ";\n"
					           + "\tif (" + t_neg + ") goto " + L_fim + ";\n"
					           + $5.traducao
					           + "\t" + L_fim + ": ;\n";
				}
				| TK_IF '(' E ')' cmd TK_ELSE cmd
				{
					string L_else = genLabel();
					string L_fim  = genLabel();
					string t_neg  = gentempcode(); add_var(t_neg, "int", true, t_neg);
					$$.traducao = $3.traducao
					           + "\t" + t_neg + " = !" + $3.label + ";\n"
					           + "\tif (" + t_neg + ") goto " + L_else + ";\n"
					           + $5.traducao
					           + "\tgoto " + L_fim + ";\n"
					           + "\t" + L_else + ": ;\n"
					           + $7.traducao
					           + "\t" + L_fim + ": ;\n";
				}
				| TK_WHILE '(' E ')'
				  {
					  string Li = genLabel(); string Lf = genLabel();
					  pilha_inicio.push_back(Li);
					  pilha_break.push_back(Lf);
				  }
				  cmd
				{
					string Li = pilha_inicio.back(); pilha_inicio.pop_back();
					string Lf = pilha_break.back();  pilha_break.pop_back();
					string t_neg = gentempcode(); add_var(t_neg, "int", true, t_neg);
					$$.traducao = "\t" + Li + ": ;\n"
					           + $3.traducao
					           + "\t" + t_neg + " = !" + $3.label + ";\n"
					           + "\tif (" + t_neg + ") goto " + Lf + ";\n"
					           + $6.traducao
					           + "\tgoto " + Li + ";\n"
					           + "\t" + Lf + ": ;\n";
				}
				| TK_DO
				  {
					  string Li = genLabel(); string Lf = genLabel();
					  pilha_inicio.push_back(Li);
					  pilha_break.push_back(Lf);
				  }
				  cmd TK_WHILE '(' E ')' ';'
				{
					string Li = pilha_inicio.back(); pilha_inicio.pop_back();
					string Lf = pilha_break.back();  pilha_break.pop_back();
					// do-while nao precisa negar: se condicao verdadeira, volta
					$$.traducao = "\t" + Li + ": ;\n"
					           + $3.traducao
					           + $6.traducao
					           + "\tif (" + $6.label + ") goto " + Li + ";\n"
					           + "\t" + Lf + ": ;\n";
				}
				| TK_FOR '(' { entra_escopo(); } for_init E ';' for_incr ')'
				  {
					  string Li = genLabel(); string Lf = genLabel();
					  pilha_inicio.push_back(Li);
					  pilha_break.push_back(Lf);
				  }
				  cmd
				{
					sai_escopo();
					string Li = pilha_inicio.back(); pilha_inicio.pop_back();
					string Lf = pilha_break.back();  pilha_break.pop_back();
					string t_neg = gentempcode(); add_var(t_neg, "int", true, t_neg);
					// $4=for_init $5=E $6=';' $7=for_incr $8=')' $9=embedded $10=cmd
					$$.traducao = $4.traducao
					           + "\t" + Li + ": ;\n"
					           + $5.traducao
					           + "\t" + t_neg + " = !" + $5.label + ";\n"
					           + "\tif (" + t_neg + ") goto " + Lf + ";\n"
					           + $10.traducao
					           + $7.traducao
					           + "\tgoto " + Li + ";\n"
					           + "\t" + Lf + ": ;\n";
				}
				| TK_SWITCH '(' E ')'
				  {
					  g_switch_expr_temp = $3.label;
					  string Lf = genLabel();
					  pilha_break.push_back(Lf);
				  }
				  '{' switch_cases switch_default '}'
				{
					string Lf = pilha_break.back(); pilha_break.pop_back();
					// $3=E  $5=embedded  $7=switch_cases  $8=switch_default
					$$.traducao = $3.traducao
					           + $7.traducao
					           + $8.traducao
					           + "\t" + Lf + ": ;\n";
				}
				;

	BLOCO		: '{' { entra_escopo(); } cmds '}'
				{
					sai_escopo();
					$$.traducao = $3.traducao;
				}
				| '{' '}'
				{
					$$.traducao = "";
				}
				;


	for_init	: D ';'
				{
					$$.traducao = $1.traducao;
				}
				| E ';'
				{
					$$.traducao = $1.traducao;
				}
				| ';'
				{
					$$.traducao = "";
				}
				;

	for_incr	: D
				{
					$$.traducao = $1.traducao;
				}
				| E
				{
					$$.traducao = $1.traducao;
				}
				| /* vazio */
				{
					$$.traducao = "";
				}
				;

	switch_cases	: /* vazio */
				{
					$$.traducao = "";
				}
				| switch_cases switch_case
				{
					$$.traducao = $1.traducao + $2.traducao;
				}
				;

	switch_case	: TK_CASE E ':' switch_stmts
				{
					string L_next = genLabel();
					string t_eq  = gentempcode(); add_var(t_eq,  "int", true, t_eq);
					string t_neg = gentempcode(); add_var(t_neg, "int", true, t_neg);
					$$.traducao = $2.traducao
					           + "\t" + t_eq  + " = (" + g_switch_expr_temp + " == " + $2.label + ");\n"
					           + "\t" + t_neg + " = !" + t_eq + ";\n"
					           + "\tif (" + t_neg + ") goto " + L_next + ";\n"
					           + $4.traducao
					           + "\t" + L_next + ": ;\n";
				}
				;

	switch_stmts	: cmds TK_BREAK ';'
				{
					$$.traducao = $1.traducao + "\tgoto " + pilha_break.back() + ";\n";
				}
				| TK_BREAK ';'
				{
					$$.traducao = "\tgoto " + pilha_break.back() + ";\n";
				}
				;

	switch_default	: /* vazio */
				{
					$$.traducao = "";
				}
				| TK_DEFAULT ':' switch_stmts
				{
					$$.traducao = $3.traducao;
				}
				;

	printf_args	: E
				{
					$$.traducao = $1.traducao;
					$$.label    = $1.label;
				}
				| printf_args ',' E
				{
					$$.traducao = $1.traducao + $3.traducao;
					$$.label    = $1.label + ", " + $3.label;
				}
				;

	scanf_args	: TK_VARIAVEL
				{
					if (!verificacao_tabela($1.label)) {
						yyerror("Variavel nao declarada: " + $1.label);
						exit(1);
					}
					variavel sv = buscar_var($1.label);
					if (sv.tipo == "string") {
						string t_bsz = gentempcode(); add_var(t_bsz, "int",    true, t_bsz);
						string t_tmp = gentempcode(); add_var(t_tmp, "string", true, t_tmp);
						string t_cnt = gentempcode(); add_var(t_cnt, "int",    true, t_cnt);
						string t_p1  = gentempcode(); add_var(t_p1,  "int",    true, t_p1);
						$$.label    = sv.temp;
						$$.traducao = "\tfree(" + sv.temp + ");\n"
						            + genMallocStr("\t" + t_bsz + " = 256;\n", t_bsz, sv.temp);
						$$.tipo     = "\t" + t_cnt + " = 0;\n"
						            + genContaChars(sv.temp, t_cnt)
						            + "\t" + t_tmp + " = " + sv.temp + ";\n"
						            + genMallocStr("\t" + t_p1 + " = " + t_cnt + " + 1;\n", t_p1, sv.temp)
						            + "\tstrcpy(" + sv.temp + ", " + t_tmp + ");\n"
						            + "\tfree(" + t_tmp + ");\n";
					} else {
						$$.label    = "&" + sv.temp;
						$$.traducao = "";
						$$.tipo     = "";
					}
				}
				| scanf_args ',' TK_VARIAVEL
				{
					if (!verificacao_tabela($3.label)) {
						yyerror("Variavel nao declarada: " + $3.label);
						exit(1);
					}
					variavel sv = buscar_var($3.label);
					if (sv.tipo == "string") {
						string t_bsz = gentempcode(); add_var(t_bsz, "int",    true, t_bsz);
						string t_tmp = gentempcode(); add_var(t_tmp, "string", true, t_tmp);
						string t_cnt = gentempcode(); add_var(t_cnt, "int",    true, t_cnt);
						string t_p1  = gentempcode(); add_var(t_p1,  "int",    true, t_p1);
						$$.label    = $1.label + ", " + sv.temp;
						$$.traducao = $1.traducao
						            + "\tfree(" + sv.temp + ");\n"
						            + genMallocStr("\t" + t_bsz + " = 256;\n", t_bsz, sv.temp);
						$$.tipo     = $1.tipo
						            + "\t" + t_cnt + " = 0;\n"
						            + genContaChars(sv.temp, t_cnt)
						            + "\t" + t_tmp + " = " + sv.temp + ";\n"
						            + genMallocStr("\t" + t_p1 + " = " + t_cnt + " + 1;\n", t_p1, sv.temp)
						            + "\tstrcpy(" + sv.temp + ", " + t_tmp + ");\n"
						            + "\tfree(" + t_tmp + ");\n";
					} else {
						$$.label    = $1.label + ", &" + sv.temp;
						$$.traducao = $1.traducao;
						$$.tipo     = $1.tipo;
					}
				}
				;

	E 			: E '+' E
				{
					atributos esquerda = $1;
					atributos direita = $3;

					if (esquerda.tipo == "string" && direita.tipo == "string") {
						// Concatenacao string + string
						string cnt1 = gentempcode();
						string cnt2 = gentempcode();
						add_var(cnt1, "int", true, cnt1);
						add_var(cnt2, "int", true, cnt2);

						$$.label = gentempcode();
						$$.tipo = "string";
						$$.is_literal = false;
						add_var($$.label, "string", true, $$.label);

						string t_sum_ss = gentempcode(); add_var(t_sum_ss, "int", true, t_sum_ss);
						string t_p1_ss  = gentempcode(); add_var(t_p1_ss,  "int", true, t_p1_ss);
						$$.traducao = esquerda.traducao + direita.traducao +
							"\t" + cnt1 + " = 0;\n" +
							genContaChars(esquerda.label, cnt1) +
							"\t" + cnt2 + " = 0;\n" +
							genContaChars(direita.label, cnt2) +
							genMallocStr("\t" + t_sum_ss + " = " + cnt1 + " + " + cnt2 + ";\n"
							           + "\t" + t_p1_ss  + " = " + t_sum_ss + " + 1;\n", t_p1_ss, $$.label) +
							"\tstrcpy(" + $$.label + ", " + esquerda.label + ");\n" +
							"\tstrcat(" + $$.label + ", " + direita.label + ");\n";

					} else if (esquerda.tipo == "string" && direita.tipo == "char") {
						// Concatenacao string + char: conta string, malloc+2, strcpy, fecha com char
						string cnt = gentempcode();
						add_var(cnt, "int", true, cnt);

						$$.label = gentempcode();
						$$.tipo = "string";
						$$.is_literal = false;
						add_var($$.label, "string", true, $$.label);

						string t_p2sc  = gentempcode(); add_var(t_p2sc,  "int",  true, t_p2sc);
						string t_np1sc = gentempcode(); add_var(t_np1sc, "int",  true, t_np1sc);
						string t_nulsc = gentempcode(); add_var(t_nulsc, "char", true, t_nulsc);
						$$.traducao = esquerda.traducao + direita.traducao +
							"\t" + cnt + " = 0;\n" +
							genContaChars(esquerda.label, cnt) +
							genMallocStr("\t" + t_p2sc + " = " + cnt + " + 2;\n", t_p2sc, $$.label) +
							"\tstrcpy(" + $$.label + ", " + esquerda.label + ");\n" +
							"\t" + t_np1sc + " = " + cnt + " + 1;\n" +
							"\t" + t_nulsc + " = '\\0';\n" +
							"\t" + $$.label + "[" + cnt + "] = " + direita.label + ";\n" +
							"\t" + $$.label + "[" + t_np1sc + "] = " + t_nulsc + ";\n";

					} else if (esquerda.tipo == "char" && direita.tipo == "string") {
						// Concatenacao char + string: conta string, malloc+2, char em [0], strcat
						string cnt = gentempcode();
						add_var(cnt, "int", true, cnt);

						$$.label = gentempcode();
						$$.tipo = "string";
						$$.is_literal = false;
						add_var($$.label, "string", true, $$.label);

						string t_p2cs  = gentempcode(); add_var(t_p2cs,  "int",  true, t_p2cs);
						string t_i0cs  = gentempcode(); add_var(t_i0cs,  "int",  true, t_i0cs);
						string t_i1cs  = gentempcode(); add_var(t_i1cs,  "int",  true, t_i1cs);
						string t_nlcs  = gentempcode(); add_var(t_nlcs,  "char", true, t_nlcs);
						$$.traducao = esquerda.traducao + direita.traducao +
							"\t" + cnt + " = 0;\n" +
							genContaChars(direita.label, cnt) +
							genMallocStr("\t" + t_p2cs + " = " + cnt + " + 2;\n", t_p2cs, $$.label) +
							"\t" + t_i0cs + " = 0;\n" +
							"\t" + t_i1cs + " = 1;\n" +
							"\t" + t_nlcs + " = '\\0';\n" +
							"\t" + $$.label + "[" + t_i0cs + "] = " + esquerda.label + ";\n" +
							"\t" + $$.label + "[" + t_i1cs + "] = " + t_nlcs + ";\n" +
							"\tstrcat(" + $$.label + ", " + direita.label + ");\n";

					} else if (esquerda.tipo == "char" && direita.tipo == "char") {
						// Concatenacao char + char: dois chars viram uma string de 2 caracteres
						$$.label = gentempcode();
						$$.tipo = "string";
						$$.is_literal = false;
						add_var($$.label, "string", true, $$.label);

						string t_sz3   = gentempcode(); add_var(t_sz3,   "int",  true, t_sz3);
						string t_i0cc  = gentempcode(); add_var(t_i0cc,  "int",  true, t_i0cc);
						string t_i1cc  = gentempcode(); add_var(t_i1cc,  "int",  true, t_i1cc);
						string t_i2cc  = gentempcode(); add_var(t_i2cc,  "int",  true, t_i2cc);
						string t_nlcc  = gentempcode(); add_var(t_nlcc,  "char", true, t_nlcc);
						$$.traducao = esquerda.traducao + direita.traducao +
							genMallocStr("\t" + t_sz3 + " = 3;\n", t_sz3, $$.label) +
							"\t" + t_i0cc + " = 0;\n" +
							"\t" + t_i1cc + " = 1;\n" +
							"\t" + t_i2cc + " = 2;\n" +
							"\t" + t_nlcc + " = '\\0';\n" +
							"\t" + $$.label + "[" + t_i0cc + "] = " + esquerda.label + ";\n" +
							"\t" + $$.label + "[" + t_i1cc + "] = " + direita.label + ";\n" +
							"\t" + $$.label + "[" + t_i2cc + "] = " + t_nlcc + ";\n";

					} else {
						string tipoFinal = checar_aritmetico(esquerda.tipo, direita.tipo);
						if(tipoFinal == "") {
							yyerror("Operacao aritmetica invalida entre '" + esquerda.tipo + "' e '" + direita.tipo + "'");
							exit(1);
						}
						if(tipoFinal == "float") {
							esquerda = converter_p_float(esquerda);
							direita = converter_p_float(direita);
						}

						$$.label = gentempcode();
						$$.tipo = tipoFinal;
						add_var($$.label, tipoFinal, true, $$.label);
						$$.traducao = esquerda.traducao + direita.traducao + "\t" + $$.label +
							" = " + esquerda.label + " + " + direita.label + ";\n";
					}
				}
				| E '-' E
				{
					atributos esquerda = $1;
					atributos direita = $3;

					string tipoFinal = checar_aritmetico(esquerda.tipo, direita.tipo);
					if(tipoFinal == "") {
						yyerror("Operacao aritmetica invalida entre '" + esquerda.tipo + "' e '" + direita.tipo + "'");
						exit(1);
					}
					if(tipoFinal == "float") {
						esquerda = converter_p_float(esquerda);
						direita = converter_p_float(direita);
					}

					$$.label = gentempcode();
					$$.tipo = tipoFinal;
					add_var($$.label, tipoFinal, true, $$.label);
					$$.traducao = esquerda.traducao + direita.traducao + "\t" + $$.label +
						" = " + esquerda.label + " - " + direita.label + ";\n";
				}
				| E '*' E
				{
					atributos esquerda = $1;
					atributos direita = $3;

					string tipoFinal = checar_aritmetico(esquerda.tipo, direita.tipo);
					if(tipoFinal == "") {
						yyerror("Operacao aritmetica invalida entre '" + esquerda.tipo + "' e '" + direita.tipo + "'");
						exit(1);
					}
					if(tipoFinal == "float") {
						esquerda = converter_p_float(esquerda);
						direita = converter_p_float(direita);
					}

					$$.label = gentempcode();
					$$.tipo = tipoFinal;
					add_var($$.label, tipoFinal, true, $$.label);
					$$.traducao = esquerda.traducao + direita.traducao + "\t" + $$.label +
						" = " + esquerda.label + " * " + direita.label + ";\n";
				}
				| E '/' E
				{
					atributos esquerda = $1;
					atributos direita = $3;

					string tipoFinal = checar_aritmetico(esquerda.tipo, direita.tipo);
					if(tipoFinal == "") {
						yyerror("Operacao aritmetica invalida entre '" + esquerda.tipo + "' e '" + direita.tipo + "'");
						exit(1);
					}
					if(tipoFinal == "float") {
						esquerda = converter_p_float(esquerda);
						direita = converter_p_float(direita);
					}

					$$.label = gentempcode();
					$$.tipo = tipoFinal;
					add_var($$.label, tipoFinal, true, $$.label);
					$$.traducao = esquerda.traducao + direita.traducao + "\t" + $$.label +
						" = " + esquerda.label + " / " + direita.label + ";\n";
				}
				| '(' E ')'
				{
					$$.label = $2.label;
					$$.traducao = $2.traducao;
					$$.tipo = $2.tipo;
				}
				| '-' E %prec UMINUS
				{
					$$.label = gentempcode();
					$$.tipo = $2.tipo;

					add_var($$.label, $$.tipo, true, $$.label);

					$$.traducao = $2.traducao + "\t" + $$.label + " = -" + $2.label + ";\n";
				}
				| TK_FLOAT__
				{
					$$.label = gentempcode();
					$$.tipo = "float";

					add_var($$.label, "float", true, $$.label);

					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				}
				| TK_NUM
				{
					$$.label = gentempcode();
					$$.tipo = "int";

					add_var($$.label, "int", true, $$.label);

					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				}
				| TK_VARIAVEL
				{
					if(!verificacao_tabela($1.label)){
						yyerror("Variavel nao declarada");
						exit(1);
					}
					variavel x = buscar_var($1.label);

					$$.label = x.temp;
					$$.tipo = x.tipo;
					$$.traducao = "";
				}
				| TK_CHAR
				{
					$$.label = gentempcode();
					$$.tipo = "char";
					add_var($$.label, "char", true, $$.label);
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				}
				| TK_BOOL
				{
					string valor = ($1.label == "true") ? "1" : "0";
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = "\t" + $$.label + " = " + valor + ";\n";
				}
				| E TK_AND E
				{
					if (!checar_logico($1.tipo) || !checar_logico($3.tipo)) {
						yyerror("Operador '&&' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					$$.label = gentempcode();
					
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " && " + $3.label + ";\n";
				}
				| E TK_OR E
				{
					if (!checar_logico($1.tipo) || !checar_logico($3.tipo)) {
						yyerror("Operador '||' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " || " + $3.label + ";\n";
				}
				| TK_NOT E
				{
					if (!checar_logico($2.tipo)) {
						yyerror("Operador '!' invalido para tipo '" + $2.tipo + "'");
						exit(1);
					}
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $2.traducao +
						"\t" + $$.label + " = !" + $2.label + ";\n";
				}
				| E TK_GT E
				{
					if (!checar_relacional($1.tipo, $3.tipo)) {
						yyerror("Operador '>' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq1 = $1, dir1 = $3;
					if (esq1.tipo == "int" && dir1.tipo == "float") esq1 = converter_p_float(esq1);
					else if (esq1.tipo == "float" && dir1.tipo == "int") dir1 = converter_p_float(dir1);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq1.traducao + dir1.traducao +
						"\t" + $$.label + " = " + esq1.label + " > " + dir1.label + ";\n";
				}
				| E TK_LT E
				{
					if (!checar_relacional($1.tipo, $3.tipo)) {
						yyerror("Operador '<' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq2 = $1, dir2 = $3;
					if (esq2.tipo == "int" && dir2.tipo == "float") esq2 = converter_p_float(esq2);
					else if (esq2.tipo == "float" && dir2.tipo == "int") dir2 = converter_p_float(dir2);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq2.traducao + dir2.traducao +
						"\t" + $$.label + " = " + esq2.label + " < " + dir2.label + ";\n";
				}
				| E TK_GE E
				{
					if (!checar_relacional($1.tipo, $3.tipo)) {
						yyerror("Operador '>=' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq3 = $1, dir3 = $3;
					if (esq3.tipo == "int" && dir3.tipo == "float") esq3 = converter_p_float(esq3);
					else if (esq3.tipo == "float" && dir3.tipo == "int") dir3 = converter_p_float(dir3);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq3.traducao + dir3.traducao +
						"\t" + $$.label + " = " + esq3.label + " >= " + dir3.label + ";\n";
				}
				| E TK_LE E
				{
					if (!checar_relacional($1.tipo, $3.tipo)) {
						yyerror("Operador '<=' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq4 = $1, dir4 = $3;
					if (esq4.tipo == "int" && dir4.tipo == "float") esq4 = converter_p_float(esq4);
					else if (esq4.tipo == "float" && dir4.tipo == "int") dir4 = converter_p_float(dir4);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq4.traducao + dir4.traducao +
						"\t" + $$.label + " = " + esq4.label + " <= " + dir4.label + ";\n";
				}
				| E TK_EQ E
				{
					if (!checar_igualdade($1.tipo, $3.tipo)) {
						yyerror("Operador '==' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq5 = $1, dir5 = $3;
					if (esq5.tipo == "int" && dir5.tipo == "float") esq5 = converter_p_float(esq5);
					else if (esq5.tipo == "float" && dir5.tipo == "int") dir5 = converter_p_float(dir5);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq5.traducao + dir5.traducao +
						"\t" + $$.label + " = " + esq5.label + " == " + dir5.label + ";\n";
				}
				| E TK_NE E
				{
					if (!checar_igualdade($1.tipo, $3.tipo)) {
						yyerror("Operador '!=' invalido entre '" + $1.tipo + "' e '" + $3.tipo + "'");
						exit(1);
					}
					atributos esq6 = $1, dir6 = $3;
					if (esq6.tipo == "int" && dir6.tipo == "float") esq6 = converter_p_float(esq6);
					else if (esq6.tipo == "float" && dir6.tipo == "int") dir6 = converter_p_float(dir6);
					$$.label = gentempcode();
					$$.tipo = "bool";
					add_var($$.label, "int", true, $$.label);
					$$.traducao = esq6.traducao + dir6.traducao +
						"\t" + $$.label + " = " + esq6.label + " != " + dir6.label + ";\n";
				}
				| TK_CAST_INT E
				{
					
					if($2.tipo != "int" && $2.tipo != "float"){
						yyerror("Cast explicito invalido: so e permitido entre int e float");
						exit(1);
					}
					
					if($2.tipo == "int"){
						$$.label = $2.label;
						$$.tipo  = "int";
						$$.traducao = $2.traducao;
					} else {
						atributos convertido = converter_p_int($2);
						$$.label = convertido.label;
						$$.tipo  = "int";
						$$.traducao = convertido.traducao;
					}
				}
				| TK_CAST_FLOAT E
				{
					
					if($2.tipo != "int" && $2.tipo != "float"){
						yyerror("Cast explicito invalido: so e permitido entre int e float");
						exit(1);
					}
					
					if($2.tipo == "float"){
						$$.label = $2.label;
						$$.tipo  = "float";
						$$.traducao = $2.traducao;
					} else {
						atributos convertido = converter_p_float($2);
						$$.label = convertido.label;
						$$.tipo  = "float";
						$$.traducao = convertido.traducao;
					}
				}
				| TK_STRING
				{
					$$.label = $1.label;
					$$.tipo = "string";
					$$.is_literal = true;
					$$.traducao = "";
				}
				| TK_VARIAVEL '[' E ']'
				{
					if (!verificacao_tabela($1.label)) {
						yyerror("Variavel nao declarada: " + $1.label);
						exit(1);
					}
					variavel v = buscar_var($1.label);
					if (v.tipo != "string") {
						yyerror("Indexacao so e permitida em variaveis do tipo 'string', mas '" + $1.label + "' e do tipo '" + v.tipo + "'");
						exit(1);
					}
					if ($3.tipo != "int") {
						yyerror("Indice deve ser do tipo 'int', mas recebeu '" + $3.tipo + "'");
						exit(1);
					}
					$$.label = gentempcode();
					$$.tipo = "char";
					add_var($$.label, "char", true, $$.label);
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + v.temp + "[" + $3.label + "];\n";
				}
				;
	D			: TK_TIPO TK_VARIAVEL
				{
					// Verifica redeclaracao apenas no escopo atual
					if(pilha_escopos.back().count($2.label)){
						yyerror("Variavel ja declarada neste escopo: " + $2.label);
						exit(1);
					}

					string temp = gentempcode();
					add_var($2.label, $1.label, false, temp);

					if ($1.label == "string") {
						// Aloca string vazia (1 byte) — reatribuicao futura dara free+realloc
						string t_cnt0  = gentempcode(); add_var(t_cnt0,  "int",  true, t_cnt0);
						string t_idx0a = gentempcode(); add_var(t_idx0a, "int",  true, t_idx0a);
						string t_nul0a = gentempcode(); add_var(t_nul0a, "char", true, t_nul0a);
						$$.traducao = genMallocStr("\t" + t_cnt0 + " = 1;\n", t_cnt0, temp)
						           + "\t" + t_idx0a + " = 0;\n"
						           + "\t" + t_nul0a + " = '\\0';\n"
						           + "\t" + temp + "[" + t_idx0a + "] = " + t_nul0a + ";\n";
					} else {
						$$.traducao = "";
					}
				}
				| TK_TIPO TK_VARIAVEL '=' E
				{
					// Verifica redeclaracao apenas no escopo atual
					if(pilha_escopos.back().count($2.label)){
						yyerror("Variavel ja declarada neste escopo: " + $2.label);
						exit(1);
					}

					if ($1.label == "string") {
						if ($4.tipo != "string") {
							yyerror("Atribuicao invalida: nao e possivel atribuir '" + $4.tipo + "' em variavel do tipo 'string'");
							exit(1);
						}
						string temp = gentempcode();
						add_var($2.label, "string", false, temp);
						if ($4.is_literal) {
							// Tamanho exato calculado em compile-time (label inclui as aspas)
							int tamanho = (int)$4.label.length() - 1;
							string t_sz_li = gentempcode(); add_var(t_sz_li, "int", true, t_sz_li);
							$$.traducao = $4.traducao +
								genMallocStr("\t" + t_sz_li + " = " + to_string(tamanho) + ";\n", t_sz_li, temp) +
								"\tstrcpy(" + temp + ", " + $4.label + ");\n";
						} else {
							// Tamanho desconhecido: conta chars sem strlen
							string cnt    = gentempcode(); add_var(cnt,    "int", true, cnt);
							string t_p1_d = gentempcode(); add_var(t_p1_d, "int", true, t_p1_d);
							$$.traducao = $4.traducao +
								"\t" + cnt + " = 0;\n" +
								genContaChars($4.label, cnt) +
								genMallocStr("\t" + t_p1_d + " = " + cnt + " + 1;\n", t_p1_d, temp) +
								"\tstrcpy(" + temp + ", " + $4.label + ");\n";
						}
					} else {
						atributos expressao = $4;
						string acao = checar_atribuicao($1.label, expressao.tipo);
						if(acao == "") {
							yyerror("Atribuicao invalida: nao e possivel atribuir '" + expressao.tipo + "' em variavel do tipo '" + $1.label + "'");
							exit(1);
						}
						if(acao == "promove") {
							expressao = converter_p_float(expressao);
						}
						string temp = gentempcode();
						add_var($2.label, $1.label, false, temp);
						$$.traducao = expressao.traducao + "\t" + temp + " = " + expressao.label + ";\n";
					}
				}
				| TK_VARIAVEL '=' E
				{
					if(!verificacao_tabela($1.label)){
						yyerror("Variavel nao declarada");
						exit(1);
					}

					variavel a = buscar_var($1.label);

					if (a.tipo == "string") {
						if ($3.tipo != "string") {
							yyerror("Atribuicao invalida: nao e possivel atribuir '" + $3.tipo + "' em variavel '" + $1.label + "' do tipo 'string'");
							exit(1);
						}
						if ($3.is_literal) {
							// Tamanho exato calculado em compile-time
							int tamanho = (int)$3.label.length() - 1;
							string t_sz_rl = gentempcode(); add_var(t_sz_rl, "int", true, t_sz_rl);
							$$.traducao = $3.traducao +
								"\tfree(" + a.temp + ");\n" +
								genMallocStr("\t" + t_sz_rl + " = " + to_string(tamanho) + ";\n", t_sz_rl, a.temp) +
								"\tstrcpy(" + a.temp + ", " + $3.label + ");\n";
						} else {
							// Contagem em runtime sem strlen
							string cnt    = gentempcode(); add_var(cnt,    "int", true, cnt);
							string t_p1_r = gentempcode(); add_var(t_p1_r, "int", true, t_p1_r);
							$$.traducao = $3.traducao +
								"\t" + cnt + " = 0;\n" +
								genContaChars($3.label, cnt) +
								"\tfree(" + a.temp + ");\n" +
								genMallocStr("\t" + t_p1_r + " = " + cnt + " + 1;\n", t_p1_r, a.temp) +
								"\tstrcpy(" + a.temp + ", " + $3.label + ");\n";
						}
					} else {
						atributos expressao = $3;

						string acao = checar_atribuicao(a.tipo, expressao.tipo);
						if(acao == "") {
							yyerror("Atribuicao invalida: nao e possivel atribuir '" + expressao.tipo + "' em variavel '" + $1.label + "' do tipo '" + a.tipo + "'");
							exit(1);
						}
						if(acao == "promove") {
							expressao = converter_p_float(expressao);
						}

						$$.traducao = expressao.traducao + "\t" + a.temp + " = " + expressao.label + ";\n";
					}
				} 
				;
	%%

	#include "lex.yy.c"

	int yyparse();

	string gentempcode()
	{
		var_temp_qnt++;
		return "t" + to_string(var_temp_qnt);
	}

	string genLabel()
	{
		label_qnt++;
		return "L" + to_string(label_qnt);
	}

	string genMallocStr(string count_code, string count_temp, string result_label)
	{
		string t_szof   = gentempcode(); add_var(t_szof,   "int", true, t_szof);
		string t_nbytes = gentempcode(); add_var(t_nbytes, "int", true, t_nbytes);
		return count_code
			+ "\t" + t_szof   + " = sizeof(char);\n"
			+ "\t" + t_nbytes + " = " + count_temp + " * " + t_szof + ";\n"
			+ "\t" + result_label + " = (char*) malloc(" + t_nbytes + ");\n";
	}

	string genContaChars(string str_label, string cnt_label)
	{
		string lb = genLabel();
		string le = genLabel();
		string t_char = gentempcode();
		string t_cond = gentempcode();
		add_var(t_char, "char", true, t_char);
		add_var(t_cond, "int",  true, t_cond);
		return "\t" + lb + ":\n"
			+ "\t" + t_char + " = " + str_label + "[" + cnt_label + "];\n"
			+ "\t" + t_cond + " = (" + t_char + " == '\\0');\n"
			+ "\tif (" + t_cond + ") goto " + le + ";\n"
			+ "\t" + cnt_label + " = " + cnt_label + " + 1;\n"
			+ "\tgoto " + lb + ";\n"
			+ "\t" + le + ": ;\n";
	}

	string chave_temp()
	{
		var_temp++;
		return "%¬" + to_string(var_temp);
	}

	void entra_escopo() {
		pilha_escopos.push_back({});
	}

	void sai_escopo() {
		pilha_escopos.pop_back();
	}

	bool verificacao_tabela(string nome) {
		// Percorre do escopo mais interno ao mais externo
		for (int i = pilha_escopos.size() - 1; i >= 0; i--) {
			if (pilha_escopos[i].find(nome) != pilha_escopos[i].end())
				return true;
		}
		return false;
	}

	variavel buscar_var(string nome) {
		for (int i = pilha_escopos.size() - 1; i >= 0; i--) {
			auto it = pilha_escopos[i].find(nome);
			if (it != pilha_escopos[i].end())
				return it->second;
		}
		yyerror("Variavel nao declarada: " + nome);
		exit(1);
	}

	void add_var(string nome, string tipo, bool temp, string vars_temp) {

		if (tipo == "string") usa_string = true;
		string tipo_c = (tipo == "bool") ? "int" : (tipo == "string") ? "char *" : tipo;

		if (!temp) {
			// Verifica redeclaracao apenas no escopo atual (topo da pilha)
			if (pilha_escopos.back().find(nome) != pilha_escopos.back().end()) {
				yyerror("Variavel ja declarada neste escopo: " + nome);
				exit(1);
			}

			variavel v;
			v.tipo = tipo;
			v.valor = "";
			v.temp = vars_temp;

			pilha_escopos.back()[nome] = v;
			var += "\t" + tipo_c + " " + vars_temp + ";\n";
		} else {
			variavel v;
			v.tipo = tipo;
			v.valor = "";
			v.temp = nome;

			pilha_escopos.back()[chave_temp()] = v;
			var += "\t" + tipo_c + " " + vars_temp + ";\n";
		}
	}

	string checar_aritmetico(string t1, string t2) {
		auto it = tab_tipos.find("aritm:" + t1 + ":" + t2);
		return (it != tab_tipos.end()) ? it->second : "";
	}

	bool checar_relacional(string t1, string t2) {
		return tab_tipos.count("relac:" + t1 + ":" + t2);
	}

	bool checar_igualdade(string t1, string t2) {
		return tab_tipos.count("igual:" + t1 + ":" + t2);
	}

	bool checar_logico(string t) {
		return tab_tipos.count("logico:" + t + ":");
	}

	string checar_atribuicao(string tv, string te) {
		auto it = tab_tipos.find("atrib:" + tv + ":" + te);
		return (it != tab_tipos.end()) ? it->second : "";
	}

	atributos converter_p_float(atributos e){

		if(e.tipo == "float"){
			return e; 
		}

		atributos novo;

		novo.label = gentempcode();
		novo.tipo = "float";

		add_var(novo.label, "float", true, novo.label);

		novo.traducao = e.traducao + "\t" + novo.label + " = (float) " + e.label + ";\n";

		return novo;
	}

	atributos converter_p_int(atributos e){

		if(e.tipo == "int"){
			return e;
		}

		atributos novo;

		novo.label = gentempcode();
		novo.tipo = "int";

		add_var(novo.label, "int", true, novo.label);

		novo.traducao = e.traducao + "\t" + novo.label + " = (int) " + e.label + ";\n";

		return novo;
	}

	int main(int argc, char* argv[])
	{
		var_temp_qnt = 0;
		var_temp = 0;
		entra_escopo(); // escopo global

		if (yyparse() == 0)
			cout << codigo_gerado;

		return 0;
	}

	void yyerror(string MSG)
	{
		cerr << "Erro na linha " << linha << ": " << MSG << endl;
	}