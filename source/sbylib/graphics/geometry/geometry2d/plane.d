module sbylib.graphics.geometry.geometry2d.plane;

auto buildGeometry() {
    import sbylib.math : vec2, vec3, vec4;
    import sbylib.graphics.geometry.geometry : transformable, GeometryBuilder, Primitive;

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
                vec4(v-0.5,0,1),
                vec3(0,0,1),
                v
            );
            add(attribute);
        }
        return build();
    }
}
