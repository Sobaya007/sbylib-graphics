module sbylib.graphics.glsl.parse.sharp;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;

import sbylib.graphics.glsl.parse.statement : ImplGraph;

class Sharp : Statement {
    string type;
    string[] values;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import std.array : empty, front;
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        tokens.expect("#");
        this.type = tokens.convert();
        this.values = [tokens.convert()];

        if (!tokens.empty && tokens.front.str == ":") {
            tokens.expect( ":");
            this.values ~= tokens.convert();
        }
    }

    override string getCode() {
        import std.format : format;

        if (this.type == "version")
            return format!"#%s %s"(this.type, this.values[0]);
        if (this.type == "extension") 
            return format!"#%s %s : %s"(this.type, this.values[0], this.values[1]);

        assert(false);
    }
}
