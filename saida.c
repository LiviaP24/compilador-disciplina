/*Compilador FOCA*/
#include <stdio.h>

int main(void) {
	int t1;
	int t2;
	int t3;
	int t4;
	int t5;
	int t6;
	int t7;
	int t8;
	int t9;
	int t10;
	int t11;
	int t12;

	t1 = 2;
	t2 = t1;
	t3 = 3;
	t4 = t3;
	t5 = 1;
	t6 = 0;
	t7 = 1;
	L1: ;
	t8 = (t6 < t4);
	t9 = !t8;
	if (t9) goto L2;
	t10 = t5 * t2;
	t5 = t10;
	t11 = t6 + t7;
	t6 = t11;
	goto L1;
	L2: ;
	t12 = t5;
	printf("%d", t12);
	return 0;
}
