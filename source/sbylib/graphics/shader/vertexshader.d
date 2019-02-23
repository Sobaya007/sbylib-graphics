module sbylib.graphics.shader.vertexshader;

import sbylib.wrapper.gl : Shader, ShaderType;

class VertexShader {

    private Shader shader;

    this(string source) {
        this.shader = new Shader(ShaderType.Vertex);
        this.shader.source = source;
    }
}
