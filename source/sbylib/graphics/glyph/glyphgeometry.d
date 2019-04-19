module sbylib.graphics.glyph.glyphgeometry;

import sbylib.graphics.glyph.glyphstore : GlyphStore;
import sbylib.graphics.geometry : Geometry, transformable;
import sbylib.math : vec4, vec2;

private struct Attribute {
    @transformable vec4 position;
    vec2 texcoord;
}

class GlyphGeometry : Geometry!Attribute {

    string font;
    int fontSize;

    this(string font, int fontSize = 256) {
        import sbylib.wrapper.gl : Primitive;
        super(Primitive.Triangle, [], []);
        this.font = font;
        this.fontSize = fontSize;
    }

    void clear() {
        this.attributeList.length = 0;
        this.indexList.length = 0;
        this.update();
    }

    void addCharacter(dchar c, vec2 pos, vec2 size) {
        auto g = glyphStore.getGlyph(c);

        auto indexOffset = cast(int)this.attributeList.length;
        this.attributeList ~= [
            Attribute(vec4(pos+vec2(0,-size.y),     0,1), vec2(g.x, g.y+g.maxHeight)),
            Attribute(vec4(pos+vec2(0,0),           0,1), vec2(g.x,g.y)),
            Attribute(vec4(pos+vec2(size.x,-size.y),0,1), vec2(g.x+g.advance,g.y+g.maxHeight)),
            Attribute(vec4(pos+vec2(size.x,0),      0,1), vec2(g.x+g.advance,g.y)),
        ];
        this.indexList ~= [
            indexOffset + 0,
            indexOffset + 1,
            indexOffset + 2,

            indexOffset + 2,
            indexOffset + 1,
            indexOffset + 3
        ];
        this.update();
    }

    auto glyphStore() {
        return GlyphStore(font, fontSize);
    }
}
