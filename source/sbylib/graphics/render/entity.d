module sbylib.graphics.render.entity;

public import sbylib.math : vec2, vec3, quat, Angle;
import sbylib.wrapper.gl : BlendFactor;
import sbylib.wrapper.glfw : Window;
import sbylib.graphics.render.renderable : Renderable;
import sbylib.graphics.geometry : IGeometry;
import sbylib.graphics.material : Mat = Material, uniform;
import std.format : format;

class Entity : Renderable {

    private IGeometry _geometry;
    protected abstract Mat _material();
    protected abstract void setUniform();

    bool blend;
    bool depthTest = true;
    bool depthWrite = true;
    BlendFactor srcFactor = BlendFactor.SrcAlpha, dstFactor = BlendFactor.OneMinusSrcAlpha;

    IGeometry geometry() {
        return _geometry;
    }

    IGeometry geometry(IGeometry _geometry) {
        this._geometry = _geometry;
        _geometry.attach(_material);
        return _geometry;
    }

    override void renderImpl() {
        import sbylib.wrapper.gl : GlFunction, GlUtils, TestFunc;

        this._material.use();
        this.setUniform();

        GlUtils.depthWrite(this.depthWrite);
        GlUtils.depthTest(this.depthTest);
        GlUtils.blend(this.blend);
        GlFunction.blendFunc(this.srcFactor, this.dstFactor);

        this.geometry.render();
    }

    protected mixin template ImplBuilder() {
        alias This = typeof(this);

        import sbylib.graphics.geometry.geometry : IGeometry;

        private enum __memberNames = {
            import std.traits : hasUDA, hasFunctionAttributes;

            string[] result;
            static foreach (mem; __traits(allMembers, This)) {
                static if (__traits(compiles, mixin("This."~mem))
                        && hasUDA!(mixin("This."~mem), uniform)
                        && hasFunctionAttributes!(mixin("This."~mem), "ref")) {
                    result ~= mem;
                }
            }
            return result;
        }();

        static class Builder {

            IGeometry geometry;

            static foreach (mem; __memberNames) {
                import std.format : format;
                import std.traits : ReturnType;

                mixin(format!"@uniform %s %s;"(ReturnType!(mixin("This."~mem)).stringof, mem));
            }

            // to avoid crash in dll
            static auto opCall() {
                return new typeof(this)();
            }

            This build() 
                in (geometry, "geometry not registered")
            {
                import std.format : format;

                auto result = new This;
                result.geometry = geometry;
                static foreach (mem; __memberNames) {
                    mixin(format!"result.%s = this.%s;"(mem, mem));
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
        import sbylib.graphics.material : Mat = Material, uniform;
        import sbylib.wrapper.gl : Texture;

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
