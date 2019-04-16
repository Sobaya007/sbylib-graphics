module sbylib.graphics.glyph.glyph;

import sbylib.wrapper.gl : Texture;

class Glyph {
    dchar character;
    long offsetX, offsetY;
    long width, height;
    long advance;
    long maxHeight;
    long x, y;
    Texture texture;

    this(dchar character,
            long offsetX, long offsetY,
            long width, long height,
            long advance,
            long maxHeight,
            Texture texture) {

        this.character = character;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.width = width;
        this.height = height;
        this.advance = advance;
        this.maxHeight = maxHeight;
        this.texture = texture;
    }
}

