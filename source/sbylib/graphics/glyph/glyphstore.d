module sbylib.graphics.glyph.glyphstore;

import sbylib.graphics.canvas : Canvas;
import sbylib.graphics.glyph.glyph : Glyph;
import sbylib.wrapper.gl : Texture;
import sbylib.wrapper.freetype : Font;

class GlyphStore {

    private Font font;
    private Canvas srcCanvas, dstCanvas;
    private int[] currentX = [0];
    private Glyph[dchar] glyph;

    static opCall(string font, int height = 256) {
        import std.typecons : Tuple;
        alias Key = Tuple!(string, int);
        static typeof(this)[Key] cache;
        auto key = Key(font, height);
        if (auto r = key in cache)
            return *r;
        return cache[key] = new GlyphStore(font, height);
    }

    private this(string font, int height) {
        import sbylib.graphics.canvas : CanvasBuilder;
        import sbylib.graphics.util : Color, pixel;
        import sbylib.wrapper.freetype : FontLoader;

        this.font = FontLoader().load(font, height);
        with (CanvasBuilder()) {
            color.enable = true;
            this.srcCanvas = build();
        }
        with (CanvasBuilder()) {
            size = [256.pixel, 256.pixel];
            color.enable = true;
            this.dstCanvas = build();
        }
    }

    Texture texture() {
        return this.dstCanvas.color.texture;
    }

    Glyph getGlyph(dchar c) {
        import sbylib.wrapper.gl : TextureBuilder, TextureInternalFormat, TextureFormat;

        if (auto r = c in glyph) return *r;

        auto info = font.getLetterInfo(c);

        with (TextureBuilder()) {
            width = cast(uint)info.width;
            height = cast(uint)info.height;
            iformat = TextureInternalFormat.R;
            format = TextureFormat.R;
            unpackAlign = 1;

            auto result = glyph[c] = 
                new Glyph(info.character,
                    info.offsetX, info.offsetY,
                    info.width, info.height,
                    info.advance,
                    info.maxHeight,
                    build(info.bitmap));

            write(c);
            return result;
        }
    }

    private void write(dchar c) {
        import std.algorithm : countUntil;

        auto g = getGlyph(c);
        auto idx = currentX.countUntil!(x => x + g.advance < this.texture.width);

        if (idx == -1) {
            if ((currentX.length + 1) * g.maxHeight < this.texture.height) {
                idx = cast(int)currentX.length;
                currentX ~= 0;
            } else {
                this.realloc(this.texture.width * 2, this.texture.height * 2);
                idx = 0;
            }
        }
        write(g, idx);
    }

    private void write(Glyph g, long idx) {
        import sbylib.wrapper.gl : TextureFilter, BufferBit;

        const x = currentX[idx];
        const y = idx * g.maxHeight;
        const dstX1 = cast(int)(x+g.offsetX);
        const dstY1 = cast(int)(y+g.offsetY);
        const dstX2 = cast(int)(dstX1 + g.width);
        const dstY2 = cast(int)(dstY1 + g.height);

        srcCanvas.color.attach(g.texture);
        dstCanvas.render(
                srcCanvas,
                0, 0, g.texture.width, g.texture.height,
                dstX1, dstY1, dstX2, dstY2,
                TextureFilter.Linear, BufferBit.Color);

        g.x = x;
        g.y = y;
        currentX[idx] += g.advance;
    }

    private void realloc(int w, int h) {
        import sbylib.graphics.canvas : CanvasBuilder;
        import sbylib.wrapper.gl : TextureFilter, BufferBit;

        auto oldTexture = this.texture;
        srcCanvas.color.attach(oldTexture);

        with (CanvasBuilder()) {
            size = [w, h];
            color.enable = true;
            this.dstCanvas = build();
        }
        dstCanvas.render(
                srcCanvas,
                0, 0, oldTexture.width, oldTexture.height,
                0, 0, oldTexture.width, oldTexture.height,
                TextureFilter.Linear, BufferBit.Color);
    }
}
