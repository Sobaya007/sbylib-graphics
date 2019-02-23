module sbylib.graphics.util.limited;

import std.traits : isNumeric;
import std.typecons : Proxy;

struct Limited(T) {

    T value;
    mixin Proxy!value;
    alias value this;

    private bool delegate(T) condition;

    static if (isNumeric!T) {

        this(T begin, T end) {
            this.condition = (T v) => begin <= v && v < end;
        }

    }

    bool accept(T v) {
        return condition(v);
    }
}

auto limited(T)(T begin, T end)
    if (isNumeric!T)
{
    return Limited!T(begin, end);
}
