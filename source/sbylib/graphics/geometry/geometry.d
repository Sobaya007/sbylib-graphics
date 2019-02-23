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

    Geometry!Attribute build() {
        return new Geometry!Attribute(primitive, attributeList, indexList);
    }
}

class Geometry(Attribute, Index = uint) : IGeometry {

    private Primitive primitive;
    private Attribute[] _attributeList;
    private Index[] indexList;
    private Buffer!Attribute vertexBuffer;
    private Buffer!Index indexBuffer;
    private VertexArray vao;

    this(Primitive primitive, Attribute[] attributeList, Index[] indexList) {
        this.primitive = primitive;
        this._attributeList = attributeList;
        this.indexList = indexList;

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

        if (this.indexBuffer)
            this.indexBuffer.bind(BufferTarget.ElementArray);
    }

    override void render() {
        import sbylib.wrapper.gl : GlFunction;

        this.vao.bind();

        if (this.indexBuffer)
            GlFunction.drawElements!(Index)(primitive, cast(uint)indexList.length);
        else
            GlFunction.drawArrays(primitive, 0, cast(uint)attributeList.length);
    }

    Attribute[] attributeList() {
        return _attributeList;
    }

    Attribute[] attributeList(Attribute[] _attributeList) {
        this._attributeList = _attributeList;
        this.update();
        return _attributeList;
    }

    void update() {
        this.vertexBuffer.sendSubData(_attributeList, BufferTarget.Array);
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

    auto rotate(Angle angle) {
        import sbylib.math : mat3, vec3;

        return this.transform(mat3.axisAngle(vec3(0,0,1), angle));
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
