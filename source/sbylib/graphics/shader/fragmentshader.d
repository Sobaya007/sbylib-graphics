module sbylib.graphics.shader.fragmentshader;

import sbylib.wrapper.gl : Shader, ShaderType;

class FragmentShader {

    private Shader shader;

    this(string source) {
        this.shader = new Shader(ShaderType.Fragment);
        this.shader.source = source;
    }
}
