module sbylib.graphics.glsl.parse.argument;

public import sbylib.graphics.glsl.parse.attributelist : AttributeList;
public import sbylib.graphics.glsl.parse.token : Token;

class Argument {
    AttributeList attributes;
    string type;
    string id;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : convert;

        this.attributes = new AttributeList(tokens);
        this.type = tokens.convert();
        this.id = tokens.convert();
    }

    string getCode() {
        import std.algorithm : filter;
        import std.array : empty, join;
        import std.format : format;

        return [
            attributes.getCode(),
            format!"%s %s"(type, id)
        ].filter!(s => !s.empty).join(" ");
    }
}
