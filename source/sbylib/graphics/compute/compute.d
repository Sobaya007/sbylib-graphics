module sbylib.graphics.compute.compute;

import sbylib.wrapper.gl : Program, UniformLoc;

abstract class Compute {
    abstract string computeShaderSource();

    Program program;

    this() {
        import sbylib.wrapper.gl : Shader, ShaderType;

        this.program = new Program;

        auto computeShader = new Shader(ShaderType.Compute);
        computeShader.source = computeShaderSource;
        this.program.attach(computeShader);

        this.program.link();
    }

    protected mixin template ComputeShaderSource(string source) {
        override string computeShaderSource() { return source; }
        mixin AddUniform!(source);
        mixin AddStorageBuffer!(source);
        mixin ImplUniform;
        mixin ImplCompute!(source);
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

        private template TypeD(string typeGLSL) {
            static if (typeGLSL == "sampler2D") {
                enum TypeD = "Texture";
            } else {
                enum TypeD = typeGLSL;
            }
        }
    }

    protected mixin template AddStorageBuffer(string source) {
        import sbylib.math : vec2, vec3, vec4, mat2, mat3, mat4;
        import sbylib.graphics.glsl : buildAST, extractBuffer;
        import sbylib.wrapper.gl : Buffer;
        import std.array : array;
        import std.string : replace;
        import sbylib.graphics.compute.storagebuffer : StorageBuffer;

        static foreach (buf; source.buildAST().extractBuffer()) {
            mixin(q{
                static class ${typeName} : StorageBuffer {
                    this(Compute compute) { super(compute, "${typeName}"); }
                    ${members}
                }
                private ${typeName} _${name};
                ${typeName} ${name}() {
                    if (_${name} is null) _${name} = new ${typeName}(this);
                    return _${name};
                }
            }.replace("${typeName}", buf.typeName)
            .replace("${members}", f(buf.members))
            .replace("${name}", buf.name));
        }
    }

    protected mixin template ImplUniform() {
        import std.traits : hasUDA;
        import sbylib.graphics.material : uniform;

        void setUniform() {
            int textureUnit;
            static foreach (mem; __traits(allMembers, typeof(this))) {
                static if (hasUDA!(mixin(mem), uniform)) {
                    setUniform!(mem)(textureUnit);
                }
            }
        }

        private void setUniform(string memberName)(ref int textureUnit) {
            import std.traits : isBasicType, isInstanceOf;
            import sbylib.wrapper.gl : GlUtils;
            import sbylib.math : Vector, Matrix;

            auto member = mixin(memberName);
            alias Type = typeof(member);
            auto loc = this.program.getUniformLocation(memberName);
            static if (isBasicType!(Type)) {
                GlUtils().uniform(loc, member);
            } else static if (isInstanceOf!(Vector, Type)) {
                GlUtils().uniform(loc, member.array);
            } else static if (isInstanceOf!(Matrix, Type) && Type.Row == Type.Column) {
                GlUtils().uniformMatrix!(Type.ElementType, Type.Row)(loc, member.array);
            } else static if (is(Type == Texture)) {
                assert(member !is null, "UniformTexture's value is null");
                Texture.activate(textureUnit);
                member.bind();
                GlUtils().uniform(loc, textureUnit);
                textureUnit++;
            } else {
                static assert(false);
            }
        }
    }

    protected mixin template ImplCompute(string source) {
        import std.array : array, front;
        import std.conv : to;
        import std.regex : ctRegex, match;
        import std.format : format;
        import sbylib.wrapper.gl : GlFunction;

        private int[] binding;

        void compute(int[3] groupNum) {
            this.program.use();
            static foreach (i, buf; source.buildAST().extractBuffer()) {
                if (binding.length <= i) {
                    auto m = buf.layoutDeclare.match(ctRegex!(`binding *= *([0-9])`));
                    binding ~= m.front.array[1].to!string.to!int;
                }
                mixin(format!"%s.bindBase(binding[i]);"(buf.name));
            }

            this.setUniform();
            GlFunction().dispatchCompute(groupNum[0], groupNum[1], groupNum[2]);
        }
    }

    protected static string f(V)(V[] vs) {
        import std.algorithm : map;
        import std.format : format;
        import std.string : join;

        return vs.map!(v => format!q{mixin GenMember!(%s, "%s");}(v.type, v.id)).join("\n");
    }
}
