@nogc
void log(A...)(A a)
{
	foreach(t; a){
		_log(t);
	}
}

@nogc
private void _log(string s) {
	import core.stdc.stdio;
    fprintf(stdout, "%s", s.ptr);
}

@nogc
private void _log(ulong l) {
	import core.stdc.stdio;
    fprintf(stdout, "%llu", l);
}

@nogc
private void _log(const(char) *s) {
	import core.stdc.stdio;
    fprintf(stdout, "%s", s);
}

@nogc
private void _log(int i) {
	import core.stdc.stdio;
    fprintf(stdout, "%i", i);
}

@nogc
private void _log(char c) {
	import core.stdc.stdio;
    fprintf(stdout, "%c", c);
}

@nogc
private void _log(float f) {
	import core.stdc.stdio;
    fprintf(stdout, "%f", f);
}
