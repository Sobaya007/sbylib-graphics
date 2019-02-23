module sbylib.graphics.glsl.parse.attributelist;

public import sbylib.graphics.glsl.parse.token : Token;
public import sbylib.graphics.glsl.parse.attribute : Attribute;

import sbylib.graphics.glsl.parse.statement : ImplGraph;
import sbylib.graphics.glsl.parse.attribute : attributeGetCode = getCode;

class AttributeList {
    Attribute[] attributes;
    alias attributes this;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : convert, isConvertible;
        import std.array : empty;

        while (!tokens.empty && tokens[0].isConvertible!(Attribute, attributeGetCode)) {
            this.attributes ~= tokens.convert!(Attribute, attributeGetCode);
        }
    }

    string getCode() {
        import std.algorithm : map;
        import std.array : join;

        return attributes.map!(a => a.attributeGetCode()).join(" ");
    }

    bool has(Attribute attr) {
        import std.algorithm : canFind;

        return attributes.canFind(attr);
    }
}

