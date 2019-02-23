module sbylib.graphics.glsl.parse.comment;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;

import sbylib.graphics.glsl.parse.statement : ImplGraph;

class Comment : Statement {

    string content;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        tokens.expect("//");
        this.content = tokens.convert();
    }

    override string getCode() {
        import std.format : format;

        return format!"//%s"(this.content);
    }
}
