	%{
	#include <iostream>
	#include <string>
	#include <map>

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

	int yylex(void);
	void yyerror(string);
	string gentempcode();
	void add_var(string, string, bool, string);
	string chave_temp();
	bool verificacao_tabela(string);
	string tipo_result(string tipo1, string tipo2);
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

					string tipoFinal = tipo_result(esquerda.tipo, direita.tipo);

					if(tipoFinal == "float"){
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

					string tipoFinal = tipo_result(esquerda.tipo, direita.tipo);

					if(tipoFinal == "float"){
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

					string tipoFinal = tipo_result(esquerda.tipo, direita.tipo);

					if(tipoFinal == "float"){
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

					string tipoFinal = tipo_result(esquerda.tipo, direita.tipo);

					if(tipoFinal == "float"){
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
					$$.label = $1.label;
					$$.traducao = "";
				}
				| TK_BOOL
				{
					if ($1.label == "true")
						$$.label = "1";
					else
						$$.label = "0";

					$$.traducao = "";
				}
				| E TK_AND E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " && " + $3.label + ";\n";
				}
				| E TK_OR E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " || " + $3.label + ";\n";
				}
				| TK_NOT E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $2.traducao +
						"\t" + $$.label + " = !" + $2.label + ";\n";
				}
				| E TK_GT E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " > " + $3.label + ";\n";
				}
				| E TK_LT E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " < " + $3.label + ";\n";
				}
				| E TK_GE E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " >= " + $3.label + ";\n";
				}
				| E TK_LE E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " <= " + $3.label + ";\n";
				}
				| E TK_EQ E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " == " + $3.label + ";\n";
				}
				| E TK_NE E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);

					$$.traducao = $1.traducao + $3.traducao +
						"\t" + $$.label + " = " + $1.label + " != " + $3.label + ";\n";
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

					if($1.label == "int" && expressao.tipo == "float"){
						yyerror("Nao pode atribuir float em variavel int");
						exit(1);
					}

					if($1.label == "float" && expressao.tipo == "int"){
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

					if(a.tipo == "float" && expressao.tipo == "int"){
						expressao = converter_p_float(expressao);
					}

					if(a.tipo == "int" && expressao.tipo == "float"){
						expressao.tipo = "int";
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

		if(tipo == "bool"){
			tipo = "int";
		}

		if(!temp){

			if(tabela.find(nome) != tabela.end()){
				yyerror("Variavel ja declarada");
				exit(1);
			}

			variavel v;
			v.tipo = tipo;
			v.valor = "";
			v.temp = vars_temp;

			tabela[nome] = v;
			var += "\t" + v.tipo + " " + vars_temp + ";" + "\n";
		}
		else {
			variavel v;
			v.tipo = tipo;
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

	string tipo_result(string tipo1, string tipo2){

		if(tipo1 == "float" || tipo2 == "float"){
			return "float";
		}

		return "int";
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