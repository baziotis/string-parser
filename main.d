import lexer;
import parser;

import core.stdc.stdio;

void parse_test() {
	initialize_lexer();

	print_is_suffix();
	print_is_prefix();

	// See the tests.txt file for a clearer view.

	// -------------
	// - TEST 1 -
	// -------------

	init_input(
	"
	name()  {\n
	\"John\"\n
	}\n
\n
	surname() {\n
		\"Doe\"\n
	}\n
\n
	fullname(first_name, sep, last_name) {\n
		first_name + (sep + last_name)\n
	}\n
	"
	);
	while(!match_token(TokenKind.EOF)) {
		decls.length += 1;
		decls[decls.length - 1] = parse_decl();
		printf("\n");
	}
	decls.length = 0;

	// -------------
	// - TEST 2 -
	// -------------

    // This test produces wrong output for tabbed string (John).
    // This can be fixed (easily) in the lexer.
	init_input(
	"
	name() {
		\"Joh\\tn\"
	}

	repeat(x) {
		x + x
	}

	cond_repeat(c, x) {
		if (c prefix \"yes\")
			if(\"yes\" prefix c)
				repeat(repeat(x))
			else
				x
		else
			x
	}
	"
	);

	while(!match_token(TokenKind.EOF)) {
		decls.length += 1;
		decls[decls.length - 1] = parse_decl();
		printf("\n");
	}
	decls.length = 0;

	// -------------
	// - TEST 3 -
	// -------------

	init_input("
	findLangType(langName) {
		if (\"Java\" prefix langName)
			if(langName prefix \"Java\")
				\"Static\"
			else
				if(\"script\" suffix langName)
					\"Dynamic\"
				else
					\"Unknown\"
		else
			if (\"script\" suffix langName)
				\"Probably Dynamic\"
			else
				\"Unknown\"
	}
	");

	while(!match_token(TokenKind.EOF)) {
		decls.length += 1;
		decls[decls.length - 1] = parse_decl();
		printf("\n");
	}
}

void main() {
	parse_test();
}
