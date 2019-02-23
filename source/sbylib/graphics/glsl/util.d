module sbylib.graphics.glsl.util;

import sbylib.graphics.glsl.parse : AST, Variable, Attribute;

struct Uniform {
    string type;
    string name;
}

Variable[] variable(AST ast) {
    import std.algorithm : map;
    import std.array : join;

    return ast.statements.map!(s => s.variable).join;
}

auto extractUniform(AST ast) {
    import std.algorithm : map, filter;
    import std.array : empty, array;

    return ast.variable
        .filter!(v => !v.attributes.empty)
        .filter!(v => v.attributes.has(Attribute.Uniform))
        .map!(v => Uniform(v.type, v.id))
        .array;
}
