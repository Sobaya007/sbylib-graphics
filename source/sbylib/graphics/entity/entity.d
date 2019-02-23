module sbylib.graphics.entity.entity;

public import sbylib.math : vec2, vec3, quat, Angle;
import sbylib.wrapper.glfw : Window;
import sbylib.graphics.renderable : Renderable;
import sbylib.graphics.geometry : IGeometry;
import sbylib.graphics.material : Mat = Material, uniform;
import std.format : format;

class Entity : Renderable {

    private IGeometry _geometry;
    abstract Mat _material();
    abstract void setUniform();
    bool depthTest;

    IGeometry geometry() {
        return _geometry;
    }

    IGeometry geometry(IGeometry _geometry) {
        this._geometry = _geometry;
        _geometry.attach(_material);
        return _geometry;
    }

    override void renderImpl() {
        import std.traits : getSymbolsByUDA;
        import sbylib.wrapper.gl : GlFunction, GlUtils, TestFunc;

        this._material.use();
        this.setUniform();

        GlUtils.depthTest(this.depthTest);
        GlFunction.depthFunc(TestFunc.Less);
        GlUtils.depthWrite(true);

        this.geometry.render();
    }

    protected mixin template ImplBuilder() {
        alias This = typeof(this);
        static struct Builder {
            IGeometry geometry;

            import std.traits : hasUDA, ReturnType, hasFunctionAttributes;
            import std.meta : Filter;
            import std.format : format;

            static foreach (mem; __traits(allMembers, This)) {
                static if (__traits(compiles, mixin("This."~mem)) && hasUDA!(mixin("This."~mem), uniform) && hasFunctionAttributes!(mixin("This."~mem), "ref")) {
                    mixin(format!"@uniform %s %s;"(ReturnType!(mixin("This."~mem)).stringof, mem));
                }
            }
            bool depthTest;

            This build() {
                auto result = new This;
                result.geometry = geometry;
                result.depthTest = depthTest;
                static foreach (mem; __traits(allMembers, This)) {
                    static if (__traits(compiles, mixin("This."~mem)) && hasUDA!(mixin("This."~mem), uniform) && hasFunctionAttributes!(mixin("This."~mem), "ref")) {
                        mixin(format!"result.%s = this.%s;"(mem, mem));
                    }
                }
                return result;
            }
        }
    }

    protected mixin template Material(MaterialType) 
        if (is(MaterialType : Mat))
    {
        import std.format : format;
        import std.traits : getSymbolsByUDA;
        import sbylib.graphics.material : Mat = Material;

        private MaterialType mat;

        MaterialType material() {
            if (mat is null) mat = new MaterialType;
            return mat;
        }

        override Mat _material() {
            return material;
        }

        static foreach (mem; getSymbolsByUDA!(MaterialType, uniform)) {
            import std.traits : hasMember;
            static if (!hasMember!(typeof(this), mem.stringof)) {
                mixin(format!"@uniform auto ref %s() { return material.%s; }"(mem.stringof, mem.stringof));
            }
        }
    }

    protected mixin template ImplUniform() {
        override void setUniform() {
            int textureUnit;
            static foreach (mem; getSymbolsByUDA!(typeof(this), uniform)) {
                setUniform!(mem.stringof)(textureUnit);
            }
        }

        private void setUniform(string memberName)(ref int textureUnit) {
            import std.traits : isBasicType, isInstanceOf;
            import sbylib.wrapper.gl : GlUtils;
            import sbylib.math : Vector, Matrix;

            auto member = mixin(memberName);
            alias Type = typeof(member);
            auto loc = this.material.getUniformLocation(memberName[5..$-2]); // assumed as 'this.memberName()'
            static if (isBasicType!(Type)) {
                GlUtils.uniform(loc, member);
            } else static if (isInstanceOf!(Vector, Type)) {
                GlUtils.uniform(loc, member.array);
            } else static if (isInstanceOf!(Matrix, Type) && Type.Row == Type.Column) {
                GlUtils.uniformMatrix!(Type.ElementType, Type.Row)(loc, member.array);
            } else static if (is(Type == Texture)) {
                assert(member !is null, "UniformTexture's value is null");
                Texture.activate(textureUnit);
                member.bind();
                GlUtils.uniform(loc, textureUnit);
                textureUnit++;
            } else {
                static assert(false);
            }
        }
    }

}
