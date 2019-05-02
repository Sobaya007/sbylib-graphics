module sbylib.graphics.glsl.parse.functions;

public import sbylib.graphics.glsl.parse.token : Token;

bool isConvertible(T, alias conv)(Token token) if (is(T == enum)){
    import std.traits : EnumMembers;

    static foreach (mem; [EnumMembers!T])
        if (conv(mem) == token.str) return true;
    return false;
}

T convert(T, alias conv)(ref Token[] tokens) if (is(T == enum)) {
    auto t = tokens[0];
    tokens = tokens[1..$];
    return convert!(T, conv)(t.str);
}

T convert(T, alias conv)(string str) if (is(T == enum)) {

    import std.format : format;
    import std.traits : EnumMembers;

    foreach (mem; [EnumMembers!T]) {
        if (conv(mem) == str)
            return mem;
    }
    assert(false, format!"%s is not %s"(str, T.stringof));
}

string convert(ref Token[] tokens)
    in(tokens.length > 0)
{
    const t = tokens[0];
    tokens = tokens[1..$];
    return t.str;
}

void expect(ref Token[] tokens, string[] expected) {
    import std.algorithm : map, canFind;
    import std.array : array, empty, join;
    import std.format : format;

    auto candidates = expected.map!(a => format!"'%s'"(a)).array.join(" or ");
    if (tokens.empty)
        throw new Exception(format!"%s was expected, but no tokens found here."(candidates));

    const token = tokens[0];
    tokens = tokens[1..$];
    if (expected.canFind(token.str) is false)
        throw new Exception(format!"Error[%d, %d]:%s was expected, not '%s'"
                (token.line, token.column, candidates, token.str));
}

void expect(ref Token[] tokens, string expected) {
    expect(tokens, [expected]);
}

string indent(bool[] isEnd) {
    import std.algorithm : map;
    import std.array : array, join;

    return isEnd.map!(e => e ? "    " : "|   ").array.join;
}
