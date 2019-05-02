module sbylib.graphics.glsl.parse.block;

public import sbylib.graphics.glsl.parse.attributelist : AttributeList;
public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;
public import sbylib.graphics.glsl.parse.blocktype : BlockType;
public import sbylib.graphics.glsl.parse.variable : Variable;

import sbylib.graphics.glsl.parse.statement : ImplGraph;
import sbylib.graphics.glsl.parse.blocktype : blockGetCode = getCode;

class Block : Statement {
    string layoutDeclare;
    AttributeList attributes;
    BlockType type;
    string id;
    Variable[] variables;
    string id2;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        if (tokens[0].str == "layout") {
            while (true) {
                auto token = tokens[0].str;
                layoutDeclare ~= token;
                tokens = tokens[1..$];

                if (token == ")") break;
            }
        }

        this.attributes = new AttributeList(tokens);
        this.type = tokens.convert!(BlockType, blockGetCode);
        this.id = tokens.convert();
        tokens.expect("{");
        while (tokens[0].str != "}") {
            this.variables ~= new Variable(tokens);
        }
        tokens.expect("}");
        if (tokens[0].str != ";")
            this.id2 = tokens.convert();
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
