module sbylib.graphics.glsl.parse.block;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;
public import sbylib.graphics.glsl.parse.blocktype : BlockType;
public import sbylib.graphics.glsl.parse.variable : Variable;

import sbylib.graphics.glsl.parse.statement : ImplGraph;
import sbylib.graphics.glsl.parse.blocktype : blockGetCode = getCode;

class Block : Statement {
    BlockType type;
    string id;
    Variable[] variables;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        this.type = tokens.convert!(BlockType, blockGetCode);
        this.id = tokens.convert();
        tokens.expect("{");
        while (tokens[0].str != "}") {
            this.variables ~= new Variable(tokens);
        }
        tokens.expect("}");
        tokens.expect(";");
    }

    override string getCode() {
        import std.algorithm : map;
        import std.array : join;
        import std.format : format;

        return format!"%s%s %s {\n%s\n}"(
                type == BlockType.Uniform ? "layout(std140)" : "",
                this.type.blockGetCode(), this.id,
                variables.map!(v => format!"  %s"(v.getCode())).join("\n"));
    }
}
