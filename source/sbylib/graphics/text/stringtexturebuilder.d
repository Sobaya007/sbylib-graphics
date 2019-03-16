module sbylib.graphics.text.stringtexturebuilder;

public import sbylib.wrapper.gl : Texture;
import sbylib.graphics.geometry.geometry : IGeometry;
import sbylib.graphics.material.material : Material, uniform;
import sbylib.graphics.render.entity : Entity;
import sbylib.graphics.util.unit : Pixel, pixel;
import sbylib.math : Vector;

struct StringTextureBuilder {

    string font;
    dstring text;

    Pixel[] widthList(Pixel h) {
        import std.algorithm : map;
        import std.array : array;
        import sbylib.graphics.text.chartexturebuilder : CharTextureBuilder;

        return text.map!((c) {
            with (CharTextureBuilder()) {
                font = this.font;
                height = h;
                character = c;
                auto advance = pixel(cast(int)build().advance);
                return advance;
            }
        }).array;
    }

    Texture build() {
        import sbylib.graphics.canvas.canvas : Canvas;
        import sbylib.graphics.canvas.canvasbuilder : CanvasBuilder;
        import sbylib.graphics.canvas.canvascontext : getContext;
        import sbylib.graphics.text.chartexturebuilder : CharTextureBuilder;
        import sbylib.graphics.util.color: Color;
        import sbylib.graphics.util.unit: pixel;
        import sbylib.math : vec2;
        import sbylib.wrapper.gl : TextureBuilder, ClearMode;
        import std.algorithm : map, sum, minElement, maxElement;
        import std.array : array;

        enum Height = 128.pixel;
        auto characterList = text.map!((c) {
            with (CharTextureBuilder()) {
                font = this.font;
                character = c;
                height = Height;
                return build();
            }
        }).array;

        const totalWidth = characterList.map!(c => c.advance).sum;
        const totalHeight = characterList.map!(c => c.maxHeight).maxElement;

        Canvas canvas;
        with (CanvasBuilder()) {
            const width = cast(int)characterList.map!(c => c.width).sum;
            size = [width, Height];
            color.enable = true;
            color.clear = Color(0);

            canvas = build();
        }

        with (canvas.getContext()) {
            clear(ClearMode.Color);

            auto pen = 0;
            foreach (c; characterList) {
                entity.tex = c.texture;
                entity.offset = vec2(c.offsetX + pen, c.offsetY);
                entity.totalSize = vec2(totalWidth, totalHeight);
                entity.render();
                pen += c.advance;
            }
        }

        return canvas.color.texture;
    }

    private CharEntity entity() {
        static CharEntity result;
        if (result) return result;

        with (CharEntity.Builder()) {
            geometry = createGeometry();
            return result = build();
        }
    }

    private IGeometry createGeometry() {
        import sbylib.graphics.geometry.geometry : GeometryBuilder, Primitive;
        import sbylib.math : vec2;

        struct Attribute {
            vec2 pos;
        }
        with (GeometryBuilder!Attribute()) {
            primitive = Primitive.TriangleStrip;
            add(Attribute(vec2(0,0)));
            add(Attribute(vec2(0,1)));
            add(Attribute(vec2(1,0)));
            add(Attribute(vec2(1,1)));
            return build();
        }
    }

    private static class TextureMaterial : Material {
        mixin VertexShaderSource!(q{
            #version 450
            in vec2 pos;
            out vec2 uv;
            uniform vec2 offset;
            uniform vec2 totalSize;
            uniform sampler2D tex;

            void main() {
                vec2 p = (offset + pos * textureSize(tex, 0)) / totalSize*2-1;
                p.y = -p.y;
                gl_Position = vec4(p, 0, 1);
                uv = pos;
            }
        });

        mixin FragmentShaderSource!(q{
            #version 450
            in vec2 uv;
            out vec4 fragColor;
            uniform sampler2D tex;

            void main() {
                fragColor = texture(tex, uv).rrrr;
            }
        });
    }

    private class CharEntity : Entity {
        mixin Material!(TextureMaterial);
        mixin ImplBuilder;
        mixin ImplUniform;
    }

}
