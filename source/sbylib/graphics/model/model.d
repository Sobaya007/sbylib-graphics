module sbylib.graphics.model.model;

public import sbylib.math : vec2, vec3, quat, Angle;
import sbylib.wrapper.assimp : AssimpScene = Scene,
       AssimpNode = Node, 
       AssimpMesh = Mesh, 
       AssimpMaterial = Material,
       AssimpPrimitiveType = PrimitiveType,
       AssimpPropertyTypeInfo = PropertyTypeInfo;
import sbylib.wrapper.gl : BlendFactor, Primitive;
import sbylib.wrapper.glfw : Window;
import sbylib.graphics.render.renderable : Renderable;
import sbylib.graphics.geometry : IGeometry, GeometryBuilder, transformable;
import sbylib.graphics.material : Mat = Material, uniform;
import sbylib.math : mat4, vec4;
import std.format : format;
import std.typecons : BitFlags;
import std.variant : Variant;

class Model : Renderable {

    protected abstract Mat _material(string);
    protected abstract void setUniform(string);

    AssimpScene scene;
    ModelNode rootNode;
    bool blend;
    bool depthTest = true;
    bool depthWrite = true;
    BlendFactor srcFactor = BlendFactor.SrcAlpha, dstFactor = BlendFactor.OneMinusSrcAlpha;
    @uniform mat4 frameMatrix;

    override void renderImpl() {
        renderNode(rootNode, mat4.identity);
    }

    private void renderNode(ModelNode node, mat4 frameMatrix) {
        frameMatrix = node.transformation * frameMatrix;
        this.frameMatrix = frameMatrix;
        foreach (mesh; node.meshes) {
            renderMesh(mesh);
        }
        foreach (child; node.children) {
            renderNode(child, frameMatrix);
        }
    }

    private void renderMesh(ModelMesh mesh) {
        import sbylib.wrapper.gl : GlFunction, GlUtils, TestFunc;
        _material(mesh.name).use();
        setUniform(mesh.name);

        GlUtils().depthWrite(this.depthWrite);
        GlUtils().depthTest(this.depthTest);
        GlUtils().blend(this.blend);
        GlFunction().blendFunc(this.srcFactor, this.dstFactor);

        if (mesh.hasAttached is false) {
            mesh.hasAttached = true;
            mesh.geom.attach(_material(mesh.name));
        }

        mesh.geom.render();
    }

    protected mixin template ImplLoad() {
        import sbylib.wrapper.assimp : Assimp, PostProcessFlag;
        import sbylib.wrapper.assimp : AssimpScene = Scene;
        static load(string path, PostProcessFlag flags = PostProcessFlag.None) {
            Assimp.initialize();
            auto res = new typeof(this);
            auto scene = AssimpScene.fromFile(path, flags);
            res.scene = scene;
            res.rootNode = new ModelNode(scene.rootNode, scene);
            return res;
        }
    }

    protected mixin template Material(Materials...) {
        import std.format : format;
        import std.traits : getSymbolsByUDA;
        import sbylib.graphics.material : Mat = Material, uniform;
        import sbylib.wrapper.gl : Texture;

        private Materials materials;

        protected override Mat _material(string name) {
            const pattern = searchPattern(name);
            foreach (ref mat; materials) {
                if (mat.pattern == pattern) {
                    return mat.getMaterial();
                }
            }
            assert(false);
        }

        protected override void setUniform(string name) {
            int textureUnit;
            const pattern = searchPattern(name);
            foreach (ref mat; materials) {
                if (mat.pattern == pattern) {
                    static foreach (mem; getSymbolsByUDA!(mat.MaterialType, uniform)) {
                        mat.setUniform!(mem.stringof)(textureUnit, mixin(mem.stringof));
                    }
                    return;
                }
            }
        }

        private string searchPattern(string name) {
            import std.regex : ctRegex, match;
            static foreach (M; Materials) {
                if (name.match(ctRegex!(M.pattern))) return M.pattern;
            }
            assert(false);
        }

        static foreach (mem; getUniformNameList()) {
            import std.string : replace;
            import std.traits : hasMember;
            static if (!hasMember!(typeof(this), mem.name)) {
                mixin(q{
                    @uniform ${type} ${name}() {
                        foreach (mat; materials) {
                            static if (__traits(hasMember, mat.MaterialType, "${name}")) {
                                return mat.getMaterial().${name};
                            }
                        }
                    }

                    @uniform void ${name}(${type} v) {
                        foreach (mat; materials) {
                            static if (__traits(hasMember, mat.MaterialType, "${name}")) {
                                mat.getMaterial().${name} = v;
                            }
                        }
                    }
                }.replace("${name}", mem.name).replace("${type}", mem.type));
            }
        }

        private static auto getUniformNameList() {
            import std.algorithm : sort, uniq;
            import std.array : array;

            struct Result {
                string name, type;
            }

            Result[] result;
            static foreach (MP; Materials) {
                static foreach (mem; getSymbolsByUDA!(MP.MaterialType, uniform)) {
                    result ~= Result(mem.stringof, typeof(mem).stringof);
                }
            }
            return result.sort!((a,b) => a.name < b.name).uniq.array;
        }
    }

    protected struct MaterialPattern(MT, string pt) 
        if (is(MT : Mat))
    {

        alias MaterialType = MT;
        enum pattern = pt;

        private MaterialType mat;

        MaterialType getMaterial() {
            if (mat is null) mat = new MaterialType;
            return mat;
        }

        void setUniform(string memberName, Type)(ref int textureUnit, Type member) {
            import std.traits : isBasicType, isInstanceOf;
            import sbylib.wrapper.gl : GlUtils;
            import sbylib.math : Vector, Matrix;

            auto loc = this.getMaterial().getUniformLocation(memberName);
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

    protected static class ModelNode {
        ModelNode[] children;
        ModelMesh[] meshes;
        mat4 transformation;

        this(AssimpNode node, AssimpScene scene) {
            import std.algorithm : map;
            import std.array : array;

            this.children = node.children.map!(c => new ModelNode(c, scene)).array;
            this.meshes = node.meshes.map!(i => new ModelMesh(scene.meshes[i], scene)).array;

            this.transformation = node.transformation;
        }
    }

    private static class ModelMesh {
        IGeometry geom;
        string name;
        Variant[string] material;
        bool hasAttached;

        this(AssimpMesh mesh, AssimpScene scene) {
            this.geom = createGeometry(mesh);
            this.name = mesh.name;
            if (mesh.materialIndex >= 0) {
                this.material = createMaterial(scene.materials[mesh.materialIndex]);
            }
        }
    }

    private static IGeometry createGeometry(AssimpMesh mesh) {
        import std.range : zip;

        struct Attribute {
            @transformable vec3 position;
            @transformable vec3 normal;
            @transformable vec3 tangent;
            @transformable vec3 bitangent;
            vec4 color;
            vec3 texcoord;
        }

        with (GeometryBuilder!(Attribute)()) {
            with (mesh) {
                primitive = conv(primitiveTypes);
                foreach (t; zip(vertices, normals)) {
                    add(Attribute(t.expand));
                }
                foreach (face; faces) {
                    foreach (i; face.indices) {
                        select(i);
                    }
                }
            }
            return build();
        }
    }

    private static Primitive conv(BitFlags!AssimpPrimitiveType t) {
        if (t & AssimpPrimitiveType.Point)    return Primitive.Point;
        if (t & AssimpPrimitiveType.Line)     return Primitive.Line;
        if (t & AssimpPrimitiveType.Triangle) return Primitive.Triangle;
        if (t & AssimpPrimitiveType.Polygon) return Primitive.Triangle;
        assert(false);
    }

    private static Variant[string] createMaterial(AssimpMaterial mat) {
        Variant[string] result;
        foreach (prop; mat.properties) {
            final switch (prop.type) {
                case AssimpPropertyTypeInfo.Float:
                    result[prop.key] = prop.data!float;
                    break;
                case AssimpPropertyTypeInfo.String:
                    result[prop.key] = prop.data!string;
                    break;
                case AssimpPropertyTypeInfo.Integer:
                    result[prop.key] = prop.data!int;
                    break;
                case AssimpPropertyTypeInfo.Buffer:
                    assert(false);
            }
        }
        return result;
    }
}
