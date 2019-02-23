module sbylib.graphics.glsl.parse.layout;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;

class Layout : Statement {
    string arguments;
    string type;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import std.array : empty, front;
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        tokens.expect("layout");
        tokens.expect("(");
        while (!tokens.empty && tokens.front.str != ")") {
            arguments ~= tokens.front.str;
            tokens = tokens[1..$];
        }
        tokens.expect(")");
        type = tokens.convert();
        tokens.expect(";");
    }

    override string getCode() {
        import std.format : format;

        return format!"layout(%s) %s;"(this.arguments, this.type);
    }
}
