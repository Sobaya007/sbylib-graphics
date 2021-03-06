module sbylib.graphics.geometry.geometrylibrary;

public import sbylib.math;
import sbylib.graphics.geometry.geometry;

struct GeometryLibrary {

    auto buildTriangle() {
        struct Attribute {
            @transformable vec4 position;
            @transformable vec3 normal;
            vec2 uv;
        }
        with (GeometryBuilder!(Attribute)()) {
            import sbylib.math : deg, sin, cos;

            primitive = Primitive.Triangle;

            foreach (i; 0..3) {
                auto angle = 90.deg + 120 * i.deg;
                auto v = vec2(cos(angle), sin(angle)) * 0.5;
                auto attribute = Attribute(
                    vec4(v,0,1),
                    vec3(0,0,1),
                    v
                );
                add(attribute);
            }
            return build();
        }
    }

    auto buildPlane() {
        struct Attribute {
            @transformable vec4 position;
            @transformable vec3 normal;
            vec2 uv;
        }
        with (GeometryBuilder!(Attribute)()) {
            import sbylib.math : deg, sin, cos;

            primitive = Primitive.TriangleStrip;

            foreach (i; 0..4) {
                auto v = vec2(i/2, i%2);
                auto attribute = Attribute(
                    vec4(v*2-1,0,1),
                    vec3(0,0,1),
                    v
                );
                add(attribute);
            }
            return build();
        }
    }

    auto buildBox() {
        import std.algorithm : map;
        import std.array : array;

        struct Attribute {
            @transformable vec4 position;
            @transformable vec3 normal;
            @transformable vec2 uv;
        }
        with (GeometryBuilder!(Attribute)()) {

            primitive = Primitive.Triangle;

            foreach (i; 0..6) {
                const s = i % 2 * 2 - 1;
                alias swap = (a, i) => vec3(a[(0+i)%3], a[(1+i)%3], a[(2+i)%3]);
                const positions = [
                    vec3(+s, +s, +s),
                    vec3(+s, +s, -s),
                    vec3(+s, -s, +s),
                    vec3(+s, -s, -s)
                ].map!(a => swap(a, i/2)).array;

                const normal = swap(vec3(+s,0,0), i/2);

                const uvs = [
                    vec2(0,0),
                    vec2(0,1),
                    vec2(1,0),
                    vec2(1,1)
                ];

                int[] order;
                if (i&1) order = [0,1,2, 2,1,3];
                else order = [2,1,0, 3,1,2];
                foreach(j; order) {
                    add(Attribute(vec4(positions[j],1), normal, uvs[j]));
                }
            }
            return build();
        }
    }
}
