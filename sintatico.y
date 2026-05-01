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

	%}

	%token TK_BOOL
	%token TK_AND TK_OR TK_NOT

	%token TK_GT TK_LT TK_GE TK_LE TK_EQ TK_NE

	%token TK_NUM
	%token TK_FLOAT__
	%token TK_VARIAVEL
	%token TK_TIPO
	%token TK_CHAR

	%start S

	%left '+''-'
	%left '*''/'
	
	%left TK_OR
	%left TK_AND
	%right TK_NOT

	%nonassoc TK_GT TK_LT TK_GE TK_LE TK_EQ TK_NE

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

	cmd			: E 
				{
					$$.traducao = $1.traducao;
				}
				| D
				{
					$$.traducao = $1.traducao;
				}
				;	

	E 			: E '+' E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
						" = " + $1.label + " + " + $3.label + ";\n";
				}
				| E '-' E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
						" = " + $1.label + " - " + $3.label + ";\n";
				}
				| E '*' E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
						" = " + $1.label + " * " + $3.label + ";\n";
				}
				| E '/' E
				{
					$$.label = gentempcode();
					add_var($$.label, "int", true, $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
						" = " + $1.label + " / " + $3.label + ";\n";
				}
				| '(' E ')'
				{
					$$.label = $2.label;
					$$.traducao = $2.traducao;
				}
				| TK_FLOAT__
				{
					$$.label = gentempcode();
					add_var($$.label, "float", true, $$.label);
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				}
				| TK_NUM
				{
					$$.label = gentempcode();
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
				| TK_VARIAVEL '=' E
				{
					if(!verificacao_tabela($1.label)){
						yyerror("Variavel nao declarada");
						exit(1);
					}

					variavel a = tabela[$1.label];
					a.valor = $3.label;
					tabela[$1.label] = a;
					$$.traducao = $3.traducao + "\t" + a.temp + " = " + $3.label + ";\n";
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

			if (tipo == "bool")
			v.tipo = "int";
			else
			v.tipo = tipo;

			v.valor = "";
			v.temp = vars_temp;
			tabela[nome] = v;
			var += "\t" + v.tipo + " " + vars_temp + ";" + "\n";
		}
		else {
			variavel v;
			if (tipo == "bool")
			v.tipo = "int";
			else
			v.tipo = tipo;
			v.valor = "";
			v.temp = nome;
			tabela[chave_temp()] = v;
			var += "\t" + v.tipo + " " + vars_temp + ";" + "\n";
		}
	}

	bool verificacao_tabela(string nome){
		if(tabela.find(nome) != tabela.end())
		{
			return true;
		}

		return false;
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