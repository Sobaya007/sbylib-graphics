module sbylib.graphics.geometry.geometry3d.icosahedron;

import std.algorithm : map;
import std.array : array;
import std.math : sqrt;
import sbylib.math : vec3, normalize;

auto buildGeometry(uint level = 0) {
    import sbylib.math : vec2, vec3, vec4;
    import sbylib.graphics.geometry.geometry : transformable, GeometryBuilder, Primitive;

    struct Attribute {
        @transformable vec4 position;
        @transformable vec3 normal;
    }
    with (GeometryBuilder!(Attribute)()) {
        primitive = Primitive.Triangle;

        auto vertexIndex = createVertexIndex(level);

        foreach (vertex; vertexIndex.vertex) {
            add(Attribute(
                vec4(vertex, 1),
                vertex));
        }
        foreach (index; vertexIndex.index) {
            select(cast(uint)index);
        }

        return build();
    }
}

private auto createVertexIndex(uint level) {
    struct Result {
        vec3[] vertex;
        size_t[] index;
    }

    if (level == 0) return Result(OriginalVertex, OriginalIndex);

    Result result;

    auto before = createVertexIndex(level-1);

    result.vertex = before.vertex;

    auto idx = result.vertex.length;
    size_t[size_t] cache;
    auto getMiddleIndex(size_t a, size_t b) {
        const key = a < b ? (a * 114_514 + b) : (b * 114_514 + a);
        if (auto r = key in cache) return *r;
        auto newVertex = normalize(result.vertex[a] + result.vertex[b]);
        result.vertex ~= newVertex;
        cache[key] = idx;
        return idx++;
    }

    auto index = before.index;
    foreach (i; 0..index.length/3) { // for each face
        const v0 = getMiddleIndex(index[i*3+0],index[i*3+1]);
        const v1 = getMiddleIndex(index[i*3+1],index[i*3+2]);
        const v2 = getMiddleIndex(index[i*3+2],index[i*3+0]);

        result.index ~= [index[i*3+0], v0, v2];
        result.index ~= [v0, index[i*3+1], v1];
        result.index ~= [v2,v1,index[i*3+2]];
        result.index ~= [v0, v1, v2];
    }

    return result;
}


private enum GoldenRatio = (1 + sqrt(5.0f)) / 2;

private enum OriginalVertex = [
    vec3(-1, +GoldenRatio, 0),
    vec3(+1, +GoldenRatio, 0),
    vec3(-1, -GoldenRatio, 0),
    vec3(+1, -GoldenRatio, 0),

    vec3(0, -1, +GoldenRatio),
    vec3(0, +1, +GoldenRatio),
    vec3(0, -1, -GoldenRatio),
    vec3(0, +1, -GoldenRatio),

    vec3(+GoldenRatio, 0, -1),
    vec3(+GoldenRatio, 0, +1),
    vec3(-GoldenRatio, 0, -1),
    vec3(-GoldenRatio, 0, +1)
].map!(v => normalize(v)).array;

private enum OriginalIndex = [
    0,  11,  5,
    0,   5,  1,
    0,   1,  7,
    0,   7, 10,
    0,  10, 11,

    1,   5,  9,
    5,  11,  4,
    11,  10,  2,
    10,   7,  6,
    7,   1,  8,

    3,   9,  4,
    3,   4,  2,
    3,   2,  6,
    3,   6,  8,
    3,   8,  9,

    4,   9,  5,
    2,   4, 11,
    6,   2, 10,
    8,   6,  7,
    9,   8,  1
];
