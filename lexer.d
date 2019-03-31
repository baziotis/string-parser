import std.stdio;
import str_intern;
import common;

const(char) *if_keyword;
const(char) *else_keyword;
const(char) *prefix_keyword;
const(char) *suffix_keyword;

enum TokenKind {
	EOF = 0,
	STR,
    NAME,
	PLUS,
	PREFIX,
	SUFFIX,
	LPAREN,
	RPAREN,
	LBRACE,
	RBRACE,
	COMMA,
	IF,
	ELSE,
};

struct Token {
    TokenKind kind;
    const(char) *start;
    const(char) *end;
	ulong ln_num;
	ulong ln_offset;
	bool is_keyword;
    union {
		const(char) *str_val;
        const(char) *name;
    };
};

const(char) *input;
ulong ln_num;
const(char) *ln_start;
Token token;

@nogc
void encountered_newline() {
	++ln_num;
	ln_start = input + 1;
}

// TODO(stefanos): Couple it with syntax_error.
@nogc
void print_line_info() {
	printf("Line: %llu:\n", ln_num);
	printf("\t");
	const(char) *reader;
	reader = ln_start;
	while(*reader != '\n' && *reader != '\0') {
		printf("%c", *reader);
		++reader;
	}
	printf("\n");
}

// initialized to 0 as a global variable.
static ushort[128] escape_lookup = [
	'n':'\n',
	'r':'\r',
	't':'\t',
	'v':'\v',
	'b':'\b',
	'a':'\a',
	'0':'\0'
];

@nogc
char escape_char() {
	assert(*input == '\\');
	++input;
	ushort val = escape_lookup[*input];
	char c = *input;
	if(val == 0 && *input != '0') {
		syntax_error("Invalid escape sequence: '\\", c, "'.");
		print_line_info();
	}
	return cast(char) val;
}

// TODO(stefanos): Change the scan of string so it doesn't care about escape sequences.
// That way we can print the string exactly as it is on the Java output.
void scan_str() {
	import core.stdc.string;
	assert(*input == '"');
	++input;
	string s = "";
	char val;
	while(*input != '\0' && *input != '"') {
		if(*input == '\n') {
			syntax_error("Cannot have newline inside string literal.");
			print_line_info();
			encountered_newline();
			print_line_info();
		} else if(*input == '\\') {
			val = escape_char();
		} else {
			val = *input;
		}
		s ~= val;
		++input;
	}
	if(*input == '\0') {
		syntax_error("Unexpected EOF inside string literal.");
		print_line_info();
	} else {
		assert(*input == '"');
		++input;
	}
	s ~= '\0';
	token.kind = TokenKind.STR;
	// NOTE(stefanos): Don't str_intern() as we won't do lookup
	// on string literals and so we don't want them to pollute the
	// string interning data structure.
	token.str_val = strdup(s.ptr);
}

void next_token() {
lex_again:
	import std.ascii;
    // skip whitespace
    while (isWhite(*input)) {
		if(*input == '\n') {
			encountered_newline();
		}
		input++;
	}
	token.ln_num = ln_num;
	token.ln_offset = input - ln_start;
    token.start = input;
    switch (*input) {

	static string generate_simple_case(string c, string k) {
		import std.format;
		return
		format!"
		case '%s':
		{
			token.kind = TokenKind.%s;
			++input;
		} break;
		"(c, k);
	}
	mixin(generate_simple_case("+", "PLUS"));
	mixin(generate_simple_case("(", "LPAREN"));
	mixin(generate_simple_case(")", "RPAREN"));
	mixin(generate_simple_case("{", "LBRACE"));
	mixin(generate_simple_case("}", "RBRACE"));
	mixin(generate_simple_case(",", "COMMA"));

	case '"':
	{
		scan_str();
	} break;

	// case 'a': case 'A': case 'b': ...
	static string generate_name_cases() {
	    string res;
	    for(char c1 = 'a', c2 = 'A'; c1 <= 'z'; ++c1, ++c2) {
	        res ~= "case '" ~ c1 ~ "': " ~ "case '" ~ c2 ~ "': ";
	    }
	    res ~= "case '_':";
	    return res;
	}
	mixin(generate_name_cases());
    {
        while (isAlphaNum(*input) || *input == '_') {
            ++input;
        }
        token.kind = TokenKind.NAME;
        token.name = str_intern_range(token.start, input);
		if(token.name == if_keyword) {
			token.kind = TokenKind.IF;
		} else if(token.name == else_keyword) {
			token.kind = TokenKind.ELSE;
		} else if(token.name == prefix_keyword) {
			token.kind = TokenKind.PREFIX;
		} else if(token.name == suffix_keyword) {
			token.kind = TokenKind.SUFFIX;
		}
	} break;

    default:
		if(*input != 0) {
			syntax_error("Unexpected token: ", *input);
		} else {
			token.kind = TokenKind.EOF;
		}
        break;
    }
    token.end = input;
}

void init_input(const(char) *s) {
    input = s;
	ln_num = 1;
	ln_start = s;
	next_token();
}

string get_kind_str(TokenKind kind) {
	switch(kind) {
		static string generate_char_case(string k, string c) {
			import std.format;
			return format!"
			case TokenKind.%s:
			{
				return \"%s\";
			} break;
			"(k, c);
		}
		mixin(generate_char_case("PLUS", "+"));
		mixin(generate_char_case("LPAREN", "("));
		mixin(generate_char_case("RPAREN", ")"));
		mixin(generate_char_case("LBRACE", "{"));
		mixin(generate_char_case("RBRACE", "}"));
		mixin(generate_char_case("COMMA", ","));
		static string generate_simple_case(string k) {
			import std.format;
			return format!"
			case TokenKind.%s:
			{
				return \"%s\";
			} break;
			"(k, k);
		}
		// TODO(stefanos): For STR, NAME, give more info.
		mixin(generate_simple_case("NAME"));
		mixin(generate_simple_case("STR"));
		mixin(generate_simple_case("IF"));
		mixin(generate_simple_case("EOF"));
		mixin(generate_simple_case("ELSE"));
		mixin(generate_simple_case("PREFIX"));
		mixin(generate_simple_case("SUFFIX"));
		default:
		{
			return "Unrecognizable token";
		} break;
	}
	return "Unrecognizable token";
}

bool match_token(TokenKind kind) {
	if(is_token(kind)) {
		next_token();
		return true;
	} else {
		return false;
	}
}

@nogc
bool is_token(TokenKind kind) {
	return token.kind == kind;
}

@nogc
bool is_keyword() {
	return (token.kind == TokenKind.IF || token.kind == TokenKind.ELSE);
}

bool expect_token(TokenKind kind) {
	if(is_token(kind)) {
		next_token();
		return true;
	} else {
		fatal_error("Expected '", get_kind_str(kind), "' got '", get_kind_str(token.kind), "'");
		return false;
	}
}

void initialize_keywords() {
	if_keyword = str_internz("if");
	else_keyword = str_internz("else");
	prefix_keyword = str_internz("prefix");
	suffix_keyword = str_internz("suffix");
}

void initialize_lexer() {
	initialize_keywords();
}
