module sbylib.graphics.text.chartexturebuilder; 
public import sbylib.wrapper.gl : Texture;
import sbylib.graphics.util.unit : Pixel, pixel;
import sbylib.wrapper.freetype : Font;

struct Glyph {
    dchar character;
    long offsetX, offsetY;
    long width, height;
    long advance;
    long maxHeight;
    Texture texture;
}

struct CharTextureBuilder {

    string font;
    dchar character;
    Pixel height = 128.pixel;

    auto build() {
        import sbylib.wrapper.gl : TextureBuilder, TextureInternalFormat, TextureFormat;
        import std.typecons : Tuple;

        alias Pair = Tuple!(Font, dchar);

        static Glyph[Pair] result;

        auto font = getFont();
        auto key = Pair(font,character);
        if (auto r = key in result) return *r;

        auto info = font.getLetterInfo(character);

        with (TextureBuilder()) {
            width = cast(uint)info.width;
            height = cast(uint)info.height;
            iformat = TextureInternalFormat.R;
            format = TextureFormat.R;
            unpackAlign = 1;

            return result[key] =
                Glyph(info.character,
                    info.offsetX, info.offsetY,
                    info.width, info.height,
                    info.advance,
                    info.maxHeight,
                    build(info.bitmap));
        }
    }

    private Font getFont() {
        import sbylib.wrapper.freetype : FontLoader;
        import std.typecons : Tuple;

        alias Pair = Tuple!(string, Pixel);
        static Font[Pair] result;
        auto key = Pair(font, height);

        if (auto r = key in result)
            return *r;

        with (FontLoader()) {
            return result[key] = load(font, cast(int)height);
        }
    }
}
