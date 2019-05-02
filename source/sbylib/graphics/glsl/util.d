module sbylib.graphics.glsl.util;

import sbylib.graphics.glsl.parse : AST, Block, Variable, Attribute, BlockType;

Variable[] variable(AST ast) {
    import std.algorithm : map;
    import std.array : join;

    return ast.statements.map!(s => s.variable).join;
}

Block[] block(AST ast) {
    import std.algorithm : map, filter;
    import std.array : array;

    return ast.statements
        .map!(s => cast(Block)s)
        .filter!(b => b !is null)
        .array;
}

auto extractUniform(AST ast) {
    import std.algorithm : map, filter;
    import std.array : empty, array;

    struct Uniform {
        string type;
        string name;
    }

    return ast.variable
        .filter!(v => !v.attributes.empty)
        .filter!(v => v.attributes.has(Attribute.Uniform))
        .map!(v => Uniform(v.type, v.id))
        .array;
}

auto extractBuffer(AST ast) {
    import std.algorithm : map, filter;
    import std.array : empty, array;
    import sbylib.graphics.glsl.parse.attribute : getCode;

    struct V {
        string type;
        string id;
    }

    struct Buffer {
        string layoutDeclare;
        string[] attributes;
        string typeName;
        V[] members;
        string name;
    }

    return ast.block
        .filter!(b => b.type == BlockType.Buffer)
        .map!(b => Buffer(
            b.layoutDeclare,
            b.attributes.map!(a => a.getCode()).array,
            b.id,
            b.variables.map!(v => V(v.type, v.id)).array,
            b.id2))
        .array;
}
