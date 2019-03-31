module str_intern;

import core.stdc.string;
import str_intern_private;

const(char) *str_intern_range(const(char) *start, const(char) *end) {
	import core.stdc.stdlib;
	import core.stdc.stdio;
	size_t len = end - start;
	// search
	for(size_t i = 0; i != interns_len; ++i) {
		if(len == interns[i].len && strncmp(interns[i].str, start, len) == 0) {
			return interns[i].str;
		}
	}
	// not found -- duplicate string and save it
	char *dup = cast(char *) malloc(len+1);
	memcpy(dup, start, len);
	dup[len] = 0;
	// GC VERSION
	if(interns_len + 1 > interns_cap) {
		interns_cap = 2*interns_cap + 1;
		interns.length = interns_cap;
	}
	interns[interns_len].len = len;
	interns[interns_len].str = dup;
	interns_len += 1;
	// NON-GC VERSION
	// push_str(len, dup);
	return dup;
}

const(char) *str_internz(T)(T t) if(is(T == string) || is(T == const(char) *)) {
	const(char) *str;
	static if(is(T == string)) {
		str = t.ptr;
	} else {
		str = t;
	}
	return str_intern_range(str, str + strlen(str));
}

void str_intern_test() {
	string a = "name";
	string b = "name";
	assert(str_internz(a) == str_internz(b));
	const(char) *c = "name1";
	assert(str_internz(c) != str_internz(b));
}
