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
	int t13;
	int t14;

	t2 = 5;
	t1 = t2;
	t4 = t1;
	t5 = 1;
	t6 = t1 + t5;
	t1 = t6;
	t3 = t4;
	printf("%d %d\n", t1, t3);
	t8 = 1;
	t9 = t1 + t8;
	t1 = t9;
	t7 = t1;
	printf("%d %d\n", t1, t7);
	t10 = t1;
	t11 = 1;
	t12 = t1 - t11;
	t1 = t12;
	printf("%d\n", t1);
	t13 = 1;
	t14 = t1 - t13;
	t1 = t14;
	printf("%d\n", t1);
	return 0;
}
