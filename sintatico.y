	%{
	#include <iostream>
	#include <string>
	#include <map>
	#include <set>

	#define YYSTYPE atributos

	using namespace std;

	int var_temp_qnt;
	int var_temp;
	int linha = 1;
	string var;
	string codigo_gerado;

	struct atributos
	{
		string label;
		string traducao;
		string tipo;
	};

	struct variavel
	{
		string temp;
		string tipo;
		string valor;
	};

	map<string, variavel> tabela;

	// Tabelas de verificacao de tipos
	map<pair<string,string>, string> tab_aritm = {
		{{"int",   "int"},   "int"},
		{{"int",   "float"}, "float"},
		{{"float", "int"},   "float"},
		{{"float", "float"}, "float"},
	};

	set<pair<string,string>> tab_relac = {
		{"int",   "int"},
		{"int",   "float"},
		{"float", "int"},
		{"float", "float"},
	};

	set<pair<string,string>> tab_igual = {
		{"int",   "int"},
		{"int",   "float"},
		{"float", "int"},
		{"float", "float"},
		{"bool",  "bool"},
		{"char",  "char"},
	};

	set<string> tab_logico = {"bool"};

	map<pair<string,string>, string> tab_atrib = {
		{{"int",   "int"},   "ok"},
		{{"float", "float"}, "ok"},
		{{"bool",  "bool"},  "ok"},
		{{"char",  "char"},  "ok"},
		{{"float", "int"},   "promove"},
	};

	int yylex(void);
	void yyerror(string);
	string gentempcode();
	void add_var(string, string, bool, string);
	string chave_temp();
	bool verificacao_tabela(string);
	string checar_aritmetico(string t1, string t2);
	bool   checar_relacional(string t1, string t2);
	bool   checar_igualdade(string t1, string t2);
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
									"#include <stdio.h>\n"
									"int main(void) {\n";
					
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
				;	

	E 			: E '+' E
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
						" = " + esquerda.label + " + " + direita.label + ";\n";
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
					variavel x = tabela[$1.label];

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
					if (!tab_logico.count($1.tipo) || !tab_logico.count($3.tipo)) {
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
					if (!tab_logico.count($1.tipo) || !tab_logico.count($3.tipo)) {
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
					if (!tab_logico.count($2.tipo)) {
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
				;
	D			: TK_TIPO TK_VARIAVEL
				{
					if(verificacao_tabela($2.label)){
						yyerror("Variavel declarada");
						exit(1);
					}

					string temp = gentempcode();
					add_var($2.label, $1.label, false, temp);
					$$.traducao = "";
				}
				| TK_TIPO TK_VARIAVEL '=' E
				{
					if(verificacao_tabela($2.label)){
						yyerror("Variavel ja declarada");
						exit(1);
					}

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
					variavel a = tabela[$2.label];
					a.valor = expressao.label;
					tabela[$2.label] = a;
					$$.traducao = expressao.traducao + "\t" + temp + " = " + expressao.label + ";\n";
				}
				| TK_VARIAVEL '=' E
				{
					if(!verificacao_tabela($1.label)){
						yyerror("Variavel nao declarada");
						exit(1);
					}

					variavel a = tabela[$1.label];

					atributos expressao = $3;

					string acao = checar_atribuicao(a.tipo, expressao.tipo);
					if(acao == "") {
						yyerror("Atribuicao invalida: nao e possivel atribuir '" + expressao.tipo + "' em variavel '" + $1.label + "' do tipo '" + a.tipo + "'");
						exit(1);
					}
					if(acao == "promove") {
						expressao = converter_p_float(expressao);
					}

					a.valor = $3.label;
					tabela[$1.label] = a;
					$$.traducao = expressao.traducao + "\t" + a.temp + " = " + expressao.label + ";\n";
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

	string chave_temp()
	{
		var_temp++;
		return "%¬" + to_string(var_temp);
	}

	void add_var(string nome, string tipo, bool temp, string vars_temp){

		

		if(!temp){

			if(tabela.find(nome) != tabela.end()){
				yyerror("Variavel ja declarada");
				exit(1);
			}

			variavel v;
			v.tipo = tipo;
			if(tipo == "bool"){
			tipo = "int";
		}
			v.valor = "";
			v.temp = vars_temp;

			tabela[nome] = v;
			var += "\t" + tipo + " " + vars_temp + ";" + "\n";
		}
		else {
			variavel v;
			v.tipo = tipo;
			if(tipo == "bool"){
			tipo = "int";
		}
			v.valor = "";
			v.temp = nome;

			tabela[chave_temp()] = v;

			var += "\t" + tipo + " " + vars_temp + ";" + "\n";
		}
	}

	bool verificacao_tabela(string nome){
		if(tabela.find(nome) != tabela.end())
		{
			return true;
		}

		return false;
	}

	string checar_aritmetico(string t1, string t2) {
		auto it = tab_aritm.find({t1, t2});
		if (it == tab_aritm.end()) return "";
		return it->second;
	}

	bool checar_relacional(string t1, string t2) {
		return tab_relac.count({t1, t2}) > 0;
	}

	bool checar_igualdade(string t1, string t2) {
		return tab_igual.count({t1, t2}) > 0;
	}

	string checar_atribuicao(string tv, string te) {
		auto it = tab_atrib.find({tv, te});
		if (it == tab_atrib.end()) return "";
		return it->second;
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

		if (yyparse() == 0)
			cout << codigo_gerado;

		return 0;
	}

	void yyerror(string MSG)
	{
		cerr << "Erro na linha " << linha << ": " << MSG << endl;
	}