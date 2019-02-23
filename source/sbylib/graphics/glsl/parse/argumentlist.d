module sbylib.graphics.glsl.parse.argumentlist;

public import sbylib.graphics.glsl.parse.argument : Argument;
public import sbylib.graphics.glsl.parse.token : Token;

import sbylib.graphics.glsl.parse.statement : ImplGraph;

class ArgumentList {
    Argument[] arguments;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : expect;

        while (tokens[0].str != ")") {
            this.arguments ~= new Argument(tokens);
            if (tokens[0].str == ",") tokens.expect(",");
        }
        tokens.expect(")");
    }

    string getCode() {
        import std.algorithm : map;
        import std.array : join;

        return arguments.map!(arg => arg.getCode()).join(", ");
    }

    //void replaceID(string delegate(string) replace) {
    //    foreach (arg; this.arguments) {
    //        arg.id = replace(arg.id);
    //    }
    //}
}

