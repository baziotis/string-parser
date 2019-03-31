import lexer;
import common;
import std.stdio;
import core.stdc.stdio;

// NOTES(stefanos):
// -- IMPORTANT: Does not cover the final call list, which is trivial
// having this code, as it already handles function calls in the parse_base_expr().
// The problem with the call list is that you can't do 1-token-lookahead to determine
// whether a call follows:
// For example:  
//         Here we know that we have decl
//               |
// name(a, b, c) {
//         Here we know that we have call
//              |
// name(a, b, c)
// That bad grammar leads us to classic parsing problems as in C language
// which are solved using a symbol table to know, upon starting the parsing,
// whether we have seen the name again (aka call) or not (aka decl).
// Note that from what can be inferred, first _all_ decls come and then
// _all_ calls, meaning you only need to find what is the first call and
// then only expect calls.

// -- You can see on several TODOs some things that could be easily
// improved, but this should cover most cases.
// -- You can check the grammar in grammar.txt

int indent_level;

// TODO(stefanos): Add the name of arguments (see below for what this solves).
struct decl {
	size_t num_args;
	const(char) *name;
};

// Wholly parsed declarations buffer.
decl[] decls;

// Find a declaration of the already (wholly) parsed ones.
decl *find_decl(const(char) *name) {
	for(size_t i = 0; i != decls.length; ++i) {
		if(decls[i].name == name) return &decls[i];
	}
	return null;
}

// General buffer.
string buffer;

// TODOs(stefanos):
/*
There are 3 important things to be done, all marked with TODOs and both
very easy.
-- Check that any name used is within scope. To do that, a decl should
be constructed at the same time of processing. That can be done simply
by setting a global variable decl, that we construct. That way, we can
check both things.
1) That a name used is within scope.
2) Allow recursion.

Note that both of these stuff are somewhat in the semantic analysis part.
*/
void parse_base_expr(bool write_to_buffer) {
	import std.format;
	import std.conv;
	// Support parenthesized expressions.
	if(match_token(TokenKind.LPAREN)) {
		if(write_to_buffer) {
			buffer ~= "(";
		} else {
			printf("(");
		}
		parse_bin_expr(write_to_buffer);
        expect_token(TokenKind.RPAREN);
		if(write_to_buffer) {
			buffer ~= ")";
		} else {
			printf(")");
		}
	} else if(is_token(TokenKind.STR)) {
		if(write_to_buffer) {
			buffer ~= "\"" ~ to!string(token.str_val) ~ "\"";
		} else {
			printf("\"%s\"", token.str_val);
		}
		next_token();
	} else if(is_token(TokenKind.NAME)) {
		if(write_to_buffer) {
			buffer ~= to!string(token.name);
		} else {
			printf("%s", token.name);
		}
		// TODO(stefanos): Assert that name is in-scope.
		const(char) *name = token.name;
		expect_token(TokenKind.NAME);
		// Check if it is a function call.
		if(match_token(TokenKind.LPAREN)) {
			if(write_to_buffer) {
				buffer ~= "(";
			} else {
				printf("(");
			}
			// TODO(stefanos): That prevents recursion because the decl
			// is pushed _after_ it's wholly processed.
			decl *d = find_decl(name);
			if(d == null) {
				fatal_error("No function '" ~ to!string(name) ~ "' declared.");
			}
			// Should have exactly num_args args.
			size_t num_args = d.num_args;
			if(num_args) {
				parse_bin_expr(write_to_buffer);
				--num_args;
				while(num_args && match_token(TokenKind.COMMA)) {
					parse_bin_expr(write_to_buffer);
					num_args--;
				}
			}
			// Close call.
			expect_token(TokenKind.RPAREN);
			if(write_to_buffer) {
				buffer ~= ")";
			} else {
				printf(")");
			}
		}
	} else {
		fatal_error("Unexpected token: ", token.name);
	}
}

// Normal binary expression. Parse lvalue, then op, then however
// many right values.
void parse_bin_expr(bool write_to_buffer) {
	parse_base_expr(write_to_buffer);
	while(match_token(TokenKind.PLUS)) {
		if(write_to_buffer) {
			buffer ~= "+";
		} else {
			printf("+");
		}
		parse_base_expr(write_to_buffer);
	}
}

@nogc
bool is_logical_op() {
	return (is_token(TokenKind.PREFIX) || is_token(TokenKind.SUFFIX));
}

// NOTE(stefanos): This is _not_ a normal binary expression.
// You can't have a PREFIX b PREFIX c
// So, you only have NAME (PREFIX | SUFFIX) NAME ...the end
void parse_logical_expr() {
	buffer.length = 0;
	parse_bin_expr(true);
	if(!is_logical_op()) {
		fatal_error("Expected prefix or suffix");
	}
	if(is_token(TokenKind.PREFIX)) {
		printf("is_prefix");
	} else {
		printf("is_suffix");
	}
	next_token();
	printf("(");
	write(buffer);
	printf(", ");
	parse_bin_expr(false);
	printf(")");
}

@nogc
void indent() {
	for(int i = 0; i != indent_level; ++i) {
		printf("\t");
	}
}

void parse_return_stmt() {
	printf("return ");
	parse_bin_expr(false);
	printf(";\n");
}

void parse_stmt() {
	indent();
	if(match_token(TokenKind.IF)) {
		printf("if");
		expect_token(TokenKind.LPAREN);
		printf("(");
		parse_logical_expr();
		expect_token(TokenKind.RPAREN);
		printf(")");
		printf("\n");
		indent_level++;
		parse_stmt();
		indent_level--;
		expect_token(TokenKind.ELSE);
		indent();
		printf("else\n");
		indent_level++;
		parse_stmt();
		indent_level--;
	} else {
		parse_return_stmt();
	}
}

decl parse_decl() {
	import std.conv;
	// Get func name
	const(char) *name = token.name;
	printf("public static String %s", token.name);
	expect_token(TokenKind.NAME);
	// Expect LPAREN
	expect_token(TokenKind.LPAREN);
	printf("(");
	// Parse args if any
	size_t num_args = 0;
	if(match_token(TokenKind.NAME)) {
		num_args++;
		printf("String %s", token.name);
		while(match_token(TokenKind.COMMA)) {
			printf(",");
			expect_token(TokenKind.NAME);
			printf("String %s", token.name);
			num_args++;
		}
	} else if(is_keyword()) {
		fatal_error("Unexpected keyword in parameter list");
	}
	// Expect RPAREN etc.
	expect_token(TokenKind.RPAREN);
	printf(")");
	expect_token(TokenKind.LBRACE);
	printf(" {\n");
	indent_level++;
	// Only one statement.
	parse_stmt();
	indent_level--;
	expect_token(TokenKind.RBRACE);
	printf("}");

	decl res = {num_args, name};
	return res;
}

// Hardcoded suffix and prefix functions.
@nogc
void print_is_suffix() {
	printf("
static boolean is_suffix(String s1, String s2) {
\tint n1 = s1.length(), n2 = s2.length();
\tif (n1 > n2)
\t\treturn false;
\tfor (int i=0; i<n1; i++)
\t\tif (s1.charAt(n1 - i - 1) != s2.charAt(n2 - i - 1))
\t\t\treturn false;
\treturn true;
}
");
}

// NOTE(stefanos): Probably for that, you can use a variation of .startsWith().
@nogc
void print_is_prefix() {
	printf("
static boolean is_prefix(String s1, String s2) {
\tint n1 = s1.length(), n2 = s2.length();
\tif (n1 > n2)
\t\treturn false;
\tfor (int i=0; i<n1; i++)
\t\tif (s1.charAt(i) != s2.charAt(i))
\t\t\treturn false;
\treturn true;
}
");
}
