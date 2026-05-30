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

	t2 = 0;
	t1 = t2;
	L1: ;
	t3 = 1;
	t4 = t1 + t3;
	t1 = t4;
	t5 = 5;
	t6 = t1 == t5;
	t7 = !t6;
	if (t7) goto L4;
	goto L2;
	L4: ;
	printf("%d\n", t1);
	L2: ;
	t8 = 10;
	t9 = t1 < t8;
	if (t9) goto L1;
	L3: ;
	return 0;
}
