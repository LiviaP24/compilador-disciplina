SCANNER := flex
SCANNER_PARAMS := lexico.l
PARSER := bison
PARSER_PARAMS := -d --yacc sintatico.y
CXXFLAGS := -Wno-free-nonheap-object
FILE := exemplos/01_soma.foca

all: glf translate

compile: glf

glf: y.tab.c lex.yy.c
		g++ $(CXXFLAGS) -o glf y.tab.c

lex.yy.c: lexico.l
		$(SCANNER) $(SCANNER_PARAMS)

y.tab.c y.tab.h: sintatico.y
		$(PARSER) $(PARSER_PARAMS)

translate: glf
		./glf < $(FILE)

run: glf
		./glf < $(FILE) > /tmp/foca_output.c && gcc /tmp/foca_output.c -o /tmp/foca_output && /tmp/foca_output

runwin: glf
		./glf < $(FILE) > saida.c && gcc saida.c -o saida.exe && ./saida.exe

test: glf
	@pass=0; fail=0; \
	for f in exemplos/*.foca; do \
		name=$$(basename $$f .foca); \
		expected="exemplos/$$name.expected"; \
		if [ -f "$$expected" ]; then \
			./glf < $$f > /tmp/_foca_out 2> /tmp/_foca_err; \
			rc=$$?; \
			if [ $$rc -eq 0 ]; then actual=/tmp/_foca_out; else actual=/tmp/_foca_err; fi; \
			if diff -q $$actual $$expected > /dev/null 2>&1; then \
				echo "  PASS: $$name"; \
				pass=$$((pass + 1)); \
			else \
				echo "  FAIL: $$name"; \
				fail=$$((fail + 1)); \
			fi; \
		fi; \
	done; \
	echo ""; \
	echo "Resultado: $$pass passou, $$fail falhou"

test-%: glf
	@name=$(patsubst test-%,%,$@); \
	foca=$$(ls exemplos/$${name}_*.foca 2>/dev/null | head -1); \
	if [ -z "$$foca" ]; then \
		echo "Exemplo nao encontrado para etapa $$name"; \
		exit 1; \
	fi; \
	expected=$$(echo $$foca | sed 's/.foca/.expected/'); \
	echo "Entrada: $$foca"; \
	echo "---"; \
	./glf < $$foca > /tmp/_foca_out 2> /tmp/_foca_err; \
	rc=$$?; \
	if [ $$rc -eq 0 ]; then cat /tmp/_foca_out; actual=/tmp/_foca_out; \
	else cat /tmp/_foca_err; actual=/tmp/_foca_err; fi; \
	echo "---"; \
	if [ -f "$$expected" ] && diff $$actual $$expected > /dev/null 2>&1; then \
		echo "PASS"; \
	else \
		echo "FAIL - Diferenca:"; \
		[ -f "$$expected" ] && diff $$actual $$expected; \
	fi

clean:
	rm -f y.tab.c y.tab.h lex.yy.c glf
