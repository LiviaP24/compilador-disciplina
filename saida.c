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

	t2 = 1;
	t1 = t2;
	L1: ;
	t3 = 10;
	t4 = t1 <= t3;
	t10 = !t4;
	if (t10) goto L2;
	t7 = 5;
	t8 = t1 == t7;
	t9 = !t8;
	if (t9) goto L3;
	goto L2;
	L3: ;
	printf("%d\n", t1);
	t5 = 1;
	t6 = t1 + t5;
	t1 = t6;
	goto L1;
	L2: ;
	return 0;
}
