module sbylib.graphics.glsl.parse.blocktype;

enum BlockType {
    Struct,
    Uniform
}

package string getCode(BlockType b) {
    final switch(b) {
    case BlockType.Struct:
        return "struct";
    case BlockType.Uniform:
        return "uniform";
    }
}
