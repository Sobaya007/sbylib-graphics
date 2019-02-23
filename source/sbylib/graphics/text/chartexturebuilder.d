module sbylib.graphics.text.chartexturebuilder;

import sbylib.graphics.util.unit : pixel;
import sbylib.wrapper.freetype : Font;

struct CharTextureBuilder {

    enum height = 128.pixel;

    string font;
    dchar character;

    auto build() {
        import sbylib.wrapper.gl : TextureBuilder, Texture, TextureInternalFormat, TextureFormat;

        struct Character {
            dchar character;
            long offsetX, offsetY;
            long width, height;
            long advance;
            long maxHeight;
            Texture texture;
        }
        static Character[dchar] result;

        if (auto r = character in result) return *r;

        auto info = getFont().getLetterInfo(character);

        with (TextureBuilder()) {
            width = cast(uint)info.width;
            height = cast(uint)info.height;
            iformat = TextureInternalFormat.R;
            format = TextureFormat.R;
            unpackAlign = 1;

            return result[character] =
                Character(info.character,
                    info.offsetX, info.offsetY,
                    info.width, info.height,
                    info.advance,
                    info.maxHeight,
                    build(info.bitmap));
        }
    }

    private Font getFont() {
        import sbylib.wrapper.freetype : FontLoader;

        static Font[string] result;

        if (auto r = font in result)
            return *r;
        return result[font] = FontLoader.load(font, height);
    }
}
