module sbylib.graphics.glsl.parse.variable;

public import sbylib.graphics.glsl.parse.attributelist : AttributeList;
public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;

class Variable : Statement {
    string layoutDeclare;
    AttributeList attributes;
    string type;
    string id;
    string assignedValue;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import std.array : empty;
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
        this.type = tokens.convert();
        this.id = tokens.convert();
        if (tokens.length > 0 && tokens[0].str == "=") {
            tokens.expect("=");
            while (tokens[0].str != ";") {
                this.assignedValue ~= tokens.convert();
            }
        }
        tokens.expect(";");
    }

    override string getCode() {
        import std.algorithm : filter;
        import std.array : empty, join;
        import std.format : format;

        return [
            format!"%s %s"(layoutDeclare, attributes.getCode()),
            format!"%s %s"(type, id),
            assignedValue ? format!"= %s"(assignedValue) : ""
        ].filter!(s => !s.empty).join(" ") ~ ";";
    }

    //void replaceID(string delegate(string) replace) {
    //    this.id = replace(this.id);
    //}
}
