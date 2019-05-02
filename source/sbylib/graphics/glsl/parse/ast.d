module sbylib.graphics.glsl.parse.ast;

import sbylib.graphics.glsl.parse.statement : Statement;
import sbylib.graphics.glsl.parse.token : Token, tokenize;

class AST {
    string name;
    Statement[] statements;

    this(Token[] tokens) {
        import std.algorithm : find, countUntil, canFind;
        import std.array : empty;
        import std.format : format;
        import sbylib.graphics.glsl.parse.functions : isConvertible;
        import sbylib.graphics.glsl.parse.attribute : Attribute, getCode;
        import sbylib.graphics.glsl.parse.block : Block;
        import sbylib.graphics.glsl.parse.comment : Comment;
        import sbylib.graphics.glsl.parse.functiondeclare : Function;
        import sbylib.graphics.glsl.parse.layout : Layout;
        import sbylib.graphics.glsl.parse.precision : Precision;
        import sbylib.graphics.glsl.parse.sharp : Sharp;
        import sbylib.graphics.glsl.parse.variable : Variable;

        while (!tokens.empty) {
            if (tokens[0].isConvertible!(Attribute, getCode)) {
                //Variable or Block(uniform)
                const lastIndex = tokens.countUntil!(t => t.str == ";");
                if (lastIndex >= 0 && tokens[0..lastIndex].canFind!(t => t.str == "{")) {
                    //Block(uniform)
                    statements ~= new Block(tokens);
                } else {
                    //Variable
                    statements ~= new Variable(tokens);
                }
            } else if (tokens[0].str == "struct") {
                statements ~= new Block(tokens);
            } else if (tokens[0].str == "precision") {
                statements ~= new Precision(tokens);
            } else if (tokens[0].str == "layout") {
                const tok = tokens.find!(t => t.str == ")");
                if (tok[2].str == ";") {
                    // if this token is variable declare's part, there is more than 1 tokens between ')' and ';'
                    statements ~= new Layout(tokens);
                } else {
                    const lastIndex = tokens.countUntil!(t => t.str == ";");
                    if (lastIndex >= 0 && tokens[0..lastIndex].canFind!(t => t.str == "{")) {
                        statements ~= new Block(tokens);
                    } else {
                        statements ~= new Variable(tokens);
                    }
                }
            } else if (tokens[0].str == "#") {
                statements ~= new Sharp(tokens);
            } else if (tokens[0].str == "//") {
                statements ~= new Comment(tokens);
            } else {
                //Variable or Function
                assert(tokens.length >= 3);
                if (tokens[2].str == "(") {
                    //Function
                    statements ~= new Function(tokens);
                } else if (tokens[2].str == "=" || tokens[2].str == ";") {
                    statements ~= new Variable(tokens);
                } else {
                    assert(false, format!"Invalid token: %s"(tokens[0]));
                }
            }
        }
    }
}

AST buildAST(string source) {
    return new AST(tokenize(source));
}

unittest {

    buildAST(q{
        #version 450
        layout(std430,binding=0) readonly buffer SSBO {
            vec4 data[];
        } gSSBO;

        void main() {
            vec4 data0 = gSSBO.data[0];
            vec4 data1 = gSSBO.data[2];
        }
    });

}
