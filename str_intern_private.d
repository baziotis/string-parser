struct InternedStr {
	size_t len;
	const(char) *str;
};

// NON-GC VERSION
// InternedStr *interns;
InternedStr[] interns;
size_t interns_len;
size_t interns_cap;

// NON-GC VERSION
/*
@nogc
void push_str(size_t len, const(char) *str) {
	import core.stdc.stdlib: realloc;
	import std.algorithm.comparison: max;
	size_t new_interns_len = interns_len + 1;
	if(new_interns_len > interns_cap || interns == null) {  // grow
		// overflow check
		assert(interns_cap <= ((size_t.max - 1) / 2));
		// minimum of 16 items
		size_t new_interns_cap = max(2 * interns_cap + 1, new_interns_len, 16);
		assert(new_interns_cap <= size_t.max / InternedStr.sizeof);
		size_t new_size = new_interns_cap * InternedStr.sizeof;
		interns_cap = new_interns_cap;
		interns = cast(InternedStr *) realloc(interns, new_size);
		assert(interns != null);
	}
	interns[interns_len].len = len;
	interns[interns_len].str = str;
	interns_len++;
}
*/
