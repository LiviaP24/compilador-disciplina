/*Compilador FOCA*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
	char * t1;
	int t2;
	int t3;
	char t4;
	int t5;
	int t6;

	t2 = 1;
	t5 = sizeof(char);
	t6 = t2 * t5;
	t1 = (char*) malloc(t6);
	t3 = 0;
	t4 = '\0';
	t1[t3] = t4;
	printf("%s\n", t1);
	return 0;
}
