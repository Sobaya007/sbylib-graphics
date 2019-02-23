module sbylib.graphics.util.functions;

public import sbylib.graphics.entity.entity : Entity;
public import sbylib.graphics.geometry.geometry : IGeometry;
public import sbylib.math;

import std.traits : isAggregateType, FieldTypeTuple, FieldNameTuple;

void initializeSobaya() {
    import sbylib.wrapper.glfw : GLFW;
    import sbylib.wrapper.freetype : FreeType;

    GLFW.initialize();
    FreeType.initialize();
}

mixin template DefineCachedValue(Type, string attribute, string name, string expression, string[] keys) {

    import std.format : format;
    import std.traits : isSomeFunction, ReturnType;

    private alias MemberType(string key) = typeof(mixin(key));

    private template VariableType(string key) {
        alias Type = MemberType!(key);
        static if (isSomeFunction!(Type)) {
            alias VariableType = ReturnType!(Type);
        } else {
            alias VariableType = Type;
        }
    }
    static foreach (key; keys) {
        mixin(format!"%s _%sSavedValue;"(VariableType!(key).stringof, key));
    }
    mixin(format!"%s _%sSavedValue;"(Type.stringof, name));

    mixin(format!q{
        %s %s %s() {
            bool _shouldUpdate = false;
            static foreach (key; keys) {
                if (mixin(format!"_%sSavedValue != %s"(key, key))) {
                    _shouldUpdate = true;
                    mixin(format!"_%sSavedValue = %s;"(key, key));
                }
            }
            if (_shouldUpdate)
                _%sSavedValue = %s;
            return _%sSavedValue;
        }
    }(attribute, Type.stringof, name, "%s", "%s", "%s", "%s", name, expression, name));
} 

mixin template ImplPos() {
    import sbylib.math : vec3;
    import sbylib.graphics.util : Pixel;
    import sbylib.wrapper.glfw : Window;

    vec3 _pos = vec3(0);

    auto ref pos() {
        return _pos;
    }

    void pos(Pixel[2] pixel) {
        import sbylib.wrapper.gl : GlUtils;
        this._pos.xy = vec2(pixel) / vec2(GlUtils.getViewport()[2..$]);
    }
}

mixin template ImplRot() {
    import sbylib.math : mat3, Angle;

    mat3 rot = mat3.identity;

    auto rotate(Angle angle) {
        this.rot *= mat3.axisAngle(vec3(0,0,1), angle);
        return this;
    }
}

mixin template ImplScale() {
    import sbylib.math : vec3;
    import sbylib.graphics.util : Pixel;

    vec3 scale = vec3(1);

    void size(Pixel[2] pixel) {
        import sbylib.wrapper.gl : GlUtils;
        this.scale.xy = vec2(pixel) / vec2(GlUtils.getViewport()[2..$]);
    }
}

mixin template ImplWorldMatrix() {
    import sbylib.graphics.material : uniform;
    import sbylib.graphics.util : DefineCachedValue;
    import std.traits : hasMember;
    import std.format : format;

    private enum hasPos = hasMember!(typeof(this), "pos");
    private enum hasRot = hasMember!(typeof(this), "rot");
    private enum hasScale = hasMember!(typeof(this), "scale");
    private enum expression = format!q{mat4.makeTRS(%s, %s, %s)}
        (hasPos   ? "pos"   : "vec3(0)",
         hasRot   ? "rot"   : "mat3.identity",
         hasScale ? "scale" : "vec3(1)");
    private enum key = 
          (hasPos   ? ["pos"]   : [])
        ~ (hasRot   ? ["rot"]   : [])
        ~ (hasScale ? ["scale"] : []);

    mixin DefineCachedValue!(mat4, "@uniform", "worldMatrix", expression, key);
}

mixin template ImplViewMatrix() {
    import sbylib.graphics.material : uniform;
    import sbylib.graphics.util : DefineCachedValue;
    import std.traits : hasMember;
    import std.format : format;

    private enum hasPos = hasMember!(typeof(this), "pos");
    private enum hasRot = hasMember!(typeof(this), "rot");
    private enum hasScale = hasMember!(typeof(this), "scale");
    private enum expression = format!q{mat4.makeInvertTRS(%s, %s, %s)}
        (hasPos   ? "pos"   : "vec3(0)",
         hasRot   ? "rot"   : "mat3.identity",
         hasScale ? "scale" : "vec3(1)");
    private enum key = 
          (hasPos   ? ["pos"]   : [])
        ~ (hasRot   ? ["rot"]   : [])
        ~ (hasScale ? ["scale"] : []);

    mixin DefineCachedValue!(mat4, "@uniform", "viewMatrix", expression, key);
}
