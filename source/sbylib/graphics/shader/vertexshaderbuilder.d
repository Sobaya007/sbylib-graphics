module sbylib.graphics.shader.vertexshaderbuilder;

public import sbylib.graphics.shader.vertexshader;

import std.format : format;

struct VertexShaderBuilder {

    private string outputCode;

    VertexShader build() {
        assert(false);
        //return new VertexShader(source);
    }

    void addTransform(VertexTransform transform) {
        assert(false);
    }
}

enum VertexTransform {
    World,
    View,
    Projection
}
