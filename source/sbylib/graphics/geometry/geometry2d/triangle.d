module sbylib.graphics.geometry.geometry2d.triangle;

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
