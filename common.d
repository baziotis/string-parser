import common_private;

@nogc
void syntax_error(A...)(A a) {
	import core.stdc.stdio;
	printf("\n");
	printf("Syntax error: ");
	log(a);
	printf("\n");
}

@nogc
void fatal_error(A...)(A a) {
	import core.stdc.stdio;
	import core.stdc.stdlib;
	printf("\n");
	printf("Syntax error: ");
	log(a);
	printf("\n");
	exit(1);
}
