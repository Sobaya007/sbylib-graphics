module sbylib.graphics.material.material;

public import sbylib.wrapper.gl : AttribLoc, UniformLoc;
import sbylib.wrapper.gl : Program;

enum uniform;

abstract class Material {

    abstract string vertexShaderSource();
    abstract string fragmentShaderSource();

    protected Program program;

    this() {
        import sbylib.wrapper.gl : Shader, ShaderType;

        this.program = new Program;

        auto vertexShader = new Shader(ShaderType.Vertex);
        vertexShader.source = vertexShaderSource;

        auto fragmentShader = new Shader(ShaderType.Fragment);
        fragmentShader.source = fragmentShaderSource;

        this.program.attach(vertexShader);
        this.program.attach(fragmentShader);
        this.program.link();
    }

    void use() {
        this.program.use();
    }

    AttribLoc getAttribLocation(string name) {
        return this.program.getAttribLocation(name);
    }

    UniformLoc getUniformLocation(string name) {
        return this.program.getUniformLocation(name);
    }

    protected mixin template VertexShaderSource(string source) {
        override string vertexShaderSource() { return source; }
        mixin AddUniform!(source);
    }

    protected mixin template FragmentShaderSource(string source) {
        override string fragmentShaderSource() { return source; }
        mixin AddUniform!(source);
    }

    protected mixin template AddUniform(string source) {
        import sbylib.math : vec2, vec3, vec4, mat2, mat3, mat4;
        import sbylib.graphics.glsl : buildAST, extractUniform, variable;
        import sbylib.wrapper.gl : Texture;
        import std.format : format;

        static foreach (uni; source.buildAST().extractUniform()) {
            static if (!__traits(hasMember, typeof(this), uni.name)) {
                mixin(format!"@uniform %s %s;"(TypeD!(uni.type), uni.name));
            }
        }

        private template TypeD(string typeGLSL) {
            static if (typeGLSL == "sampler2D") {
                enum TypeD = "Texture";
            } else {
                enum TypeD = typeGLSL;
            }
        }
    }
}
