module sbylib.graphics.material.material;

public import sbylib.wrapper.gl : AttribLoc, UniformLoc;
import sbylib.wrapper.gl : Program;

enum uniform;

abstract class Material {

    abstract string vertexShaderSource();
    abstract string fragmentShaderSource();
    string geometryShaderSource() { return ""; }
    string tessellationControlShaderSource() { return ""; }
    string tessellationEvaluationShaderSource() { return ""; }
    int patchVertices() { return -1; }
    bool hasTessallation() { return false; }

    protected Program program;

    this() {
        import sbylib.wrapper.gl : Shader, ShaderType;

        this.program = new Program;

        auto vertexShader = new Shader(ShaderType.Vertex);
        vertexShader.source = vertexShaderSource;
        this.program.attach(vertexShader);

        auto fragmentShader = new Shader(ShaderType.Fragment);
        fragmentShader.source = fragmentShaderSource;
        this.program.attach(fragmentShader);

        if (geometryShaderSource.length > 0) {
            auto geometryShader = new Shader(ShaderType.Geometry);
            geometryShader.source = geometryShaderSource;
            this.program.attach(geometryShader);
        }

        if (tessellationControlShaderSource.length > 0) {
            auto tessellationControlShader = new Shader(ShaderType.TessControl);
            tessellationControlShader.source = tessellationControlShaderSource;
            this.program.attach(tessellationControlShader);
        }

        if (tessellationEvaluationShaderSource.length > 0) {
            auto tessellationEvaluationShader = new Shader(ShaderType.TessEvaluation);
            tessellationEvaluationShader.source = tessellationEvaluationShaderSource;
            this.program.attach(tessellationEvaluationShader);
        }

        this.program.link();

        assert((tessellationControlShaderSource.length > 0
                && tessellationEvaluationShaderSource.length > 0
                && patchVertices >= 0)
            || (tessellationControlShaderSource.length == 0
            && tessellationEvaluationShaderSource.length == 0
            && patchVertices == -1),
            "If you want to use tessellation shader, you must mixin all of 'TessellationControlShaderSource', 'TessellationEvaluationShaderSource' and 'PatchVertices'");
    }

    void use() {
        import sbylib.wrapper.gl : GlFunction, PatchParamName;

        if (patchVertices > 0) {
            GlFunction().setPatchParameter(PatchParamName.Vertices, patchVertices);
        }
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

    protected mixin template GeometryShaderSource(string source) {
        override string geometryShaderSource() { return source; }
        mixin AddUniform!(source);
    }

    protected mixin template TessellationControlShaderSource(string source) {
        override string tessellationControlShaderSource() { return source; }
        mixin AddUniform!(source);
    }

    protected mixin template TessellationEvaluationShaderSource(string source) {
        override string tessellationEvaluationShaderSource() { return source; }
        override bool hasTessallation() { return true; }
        mixin AddUniform!(source);
    }

    protected mixin template PatchVertices(int vertices) {
        override int patchVertices() { return vertices; }
    }

    protected mixin template AddUniform(string source) {
        import sbylib.math : vec2, vec3, vec4, mat2, mat3, mat4;
        import sbylib.graphics.glsl : buildAST, extractUniform, variable;
        import sbylib.graphics.material : uniform;
        import sbylib.wrapper.gl : Texture;
        import std.format : format;

        static foreach (uni; source.buildAST().extractUniform()) {
            static if (!__traits(hasMember, typeof(this), uni.name)) {
                mixin(format!"@uniform %s %s;"(TypeD!(uni.type), uni.name));
            }
        }
    }

    protected template TypeD(string typeGLSL) {
        static if (typeGLSL == "sampler2D") {
            enum TypeD = "Texture";
        } else {
            enum TypeD = typeGLSL;
        }
    }
}
