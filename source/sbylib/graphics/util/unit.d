module sbylib.graphics.util.unit;

import std.typecons : Proxy;

struct Pixel {
    int value;
    alias value this;

    mixin Proxy!value;

    this(int value) {
        this.value = value;
    }
}

Pixel pixel(int value) {
    return Pixel(value);
}
