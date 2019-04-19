module sbylib.graphics.geometry.geometry;

public import sbylib.math;
public import sbylib.wrapper.gl : Primitive;

import sbylib.graphics.material : Material;
import sbylib.wrapper.gl : Buffer, BufferTarget, VertexArray;

enum transformable;

interface IGeometry {
    void attach(Material);
    void render();
}

struct GeometryBuilder(Attribute, Index = uint) {

    private Attribute[] attributeList;
    private Index[] indexList;

    Primitive primitive;

    void add(Attribute attribute) {
        this.attributeList ~= attribute;
    }

    void select(Index index) {
        indexList ~= index;
    }

    Geometry!Attribute build() const {
        return new Geometry!Attribute(primitive, attributeList, indexList);
    }
}

class Geometry(Attribute, Index = uint) : IGeometry {

    Primitive primitive;
    private Attribute[] _attributeList;
    private Index[] _indexList;
    private Buffer!Attribute vertexBuffer;
    private Buffer!Index indexBuffer;
    private VertexArray vao;

    this(const Primitive primitive, const Attribute[] attributeList, const Index[] indexList) {
        this.primitive = primitive;
        this._attributeList = attributeList.dup;
        this._indexList = indexList.dup;

        this.vao = new VertexArray;

        this.vertexBuffer = new Buffer!Attribute;
        this.vertexBuffer.sendData(attributeList, BufferTarget.Array);

        if (indexList) {
            this.indexBuffer = new Buffer!Index;
            this.indexBuffer.sendData(indexList, BufferTarget.ElementArray);
        }
    }

    override void attach(Material material) {
        import std.traits : isSomeFunction;
        import sbylib.wrapper.gl : GlFunction;

        this.vao.bind();

        int offset;
        static foreach(mem; __traits(allMembers, Attribute)) {{
            enum Member(string mem) = "Attribute."~mem;
            alias E = ElementType!(typeof(mixin(Member!mem)));
            static if (!isSomeFunction!(mixin(Member!(mem)))) {
                auto loc = material.getAttribLocation(mem);
                const size = mixin(Member!(mem)).sizeof;
                const dimension = size / E.sizeof;
                const stride = Attribute.sizeof;

                if (loc != -1) {
                    this.vao.enable(loc);
                    this.vertexBuffer.bind(BufferTarget.Array);
                    GlFunction.vertexAttribPointer!E(loc, dimension, false, stride, offset);
                }

                offset += size;
            }
        }}
    }

    override void render() {
        import sbylib.wrapper.gl : GlFunction;

        this.vao.bind();

        if (this.indexBuffer)
            this.indexBuffer.bind(BufferTarget.ElementArray);

        if (this.indexBuffer)
            GlFunction.drawElements!(Index)(primitive, cast(uint)indexList.length);
        else
            GlFunction.drawArrays(primitive, 0, cast(uint)attributeList.length);
    }

    auto ref attributeList() inout {
        return _attributeList;
    }

    auto ref indexList() inout {
        return _indexList;
    }

    auto transform(mat3 m) {
        import std.traits : isInstanceOf, hasUDA;

        foreach (ref attribute; attributeList) {
            enum Member(string mem) = "attribute."~mem;
            alias Type(string mem) = typeof(mixin(Member!(mem)));

            static foreach (mem; __traits(allMembers, Attribute)) {
                static if (isInstanceOf!(Vector, Type!(mem)) && hasUDA!(mixin(Member!(mem)), transformable)) {
                    static if (Type!(mem).Dimension == 2) {
                        mixin(Member!(mem)) = (m * vec3(mixin(Member!(mem)), 0)).xy;
                    } else static if (Type!(mem).Dimension == 3) {
                        mixin(Member!(mem)) = m * mixin(Member!(mem));
                    } else static if (Type!(mem).Dimension == 4) {
                        mixin(Member!(mem)) = Type!(mem)(m * mixin(Member!(mem)).xyz, 1);
                    }
                }
            }
        }
        update();
        return this;
    }

    auto transform(mat4 m) {
        import std.traits : isInstanceOf, hasUDA;

        foreach (ref attribute; attributeList) {
            enum Member(string mem) = "attribute."~mem;
            alias Type(string mem) = typeof(mixin(Member!(mem)));

            static foreach (mem; __traits(allMembers, Attribute)) {
                static if (isInstanceOf!(Vector, Type!(mem)) && hasUDA!(mixin(Member!(mem)), transformable)) {
                    static if (Type!(mem).Dimension == 2) {
                        mixin(Member!(mem)) = (m * vec4(mixin(Member!(mem)), 0, 0)).xy;
                    } else static if (Type!(mem).Dimension == 3) {
                        mixin(Member!(mem)) = (m * vec4(mixin(Member!(mem)), 0)).xyz;
                    } else static if (Type!(mem).Dimension == 4) {
                        mixin(Member!(mem)) = m * mixin(Member!(mem));
                    }
                }
            }
        }
        update();
        return this;
    }

    auto rotate(Angle angle) {
        import sbylib.math : mat3, vec3;

        return this.transform(mat3.axisAngle(vec3(0,0,1), angle));
    }

    void update() {
        vertexBuffer.sendData(attributeList, BufferTarget.Array);
        if (indexList) {
            if (!indexBuffer) indexBuffer = new Buffer!Index;
            indexBuffer.sendData(indexList, BufferTarget.ElementArray);
        }
    }

    private template ElementType(T) {

        import sbylib.math : isVector;

        static if (isVector!(T)) {
            alias ElementType = T.ElementType;
        } else {
            alias ElementType = T;
        }
    }
}
