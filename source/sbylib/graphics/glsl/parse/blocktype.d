module sbylib.graphics.glsl.parse.blocktype;

enum BlockType {
    Struct,
    Uniform,
    Buffer,
}

package string getCode(BlockType b) {
    final switch(b) {
    case BlockType.Struct:
        return "struct";
    case BlockType.Uniform:
        return "uniform";
    case BlockType.Buffer:
        return "buffer";
    }
}
