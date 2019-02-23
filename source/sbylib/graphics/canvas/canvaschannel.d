module sbylib.graphics.canvas.canvaschannel;

public import sbylib.math : vec4;
public import sbylib.graphics.util.color : Color;
public import sbylib.wrapper.gl : Texture, FramebufferAttachType;

struct ChannelConfig(T) {
    T clear;
    bool enable;
}

class ColorChannel {

    enum AttachType = FramebufferAttachType.Color0;

    Texture texture;
    Color clear = Color.Black;

    this() {}

    this(int[2] size) {
        import sbylib.wrapper.gl : Texture, TextureBuilder, TextureTarget, TextureInternalFormat, TextureFormat;

        with (TextureBuilder()) {
            width = size[0];
            height = size[1];
            target = TextureTarget.Tex2D;
            mipmapLevel = 0;
            iformat = TextureInternalFormat.RGBA32F;
            format = TextureFormat.RGBA;

            this.texture = build();
        }
    }

    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearColor(clear.r, clear.g, clear.b, clear.a);
    }
}

class DepthChannel {

    enum AttachType = FramebufferAttachType.Depth;
    
    Texture texture;
    float clear = 1;

    this() {}

    this(int[2] size) {
        import sbylib.wrapper.gl : Texture, TextureBuilder, TextureTarget, TextureInternalFormat, TextureFormat;

        with (TextureBuilder()) {
            width = size[0];
            height = size[1];
            target = TextureTarget.Tex2D;
            mipmapLevel = 0;
            iformat = TextureInternalFormat.Depth;
            format = TextureFormat.Depth;

            this.texture = build();
        }
    }

    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearDepth(clear);
    }
}

class StencilChannel {
    
    enum AttachType = FramebufferAttachType.Stencil;

    Texture texture;
    int clear = 0;

    this() {}

    this(int[2] size) {
        import sbylib.wrapper.gl : Texture, TextureBuilder, TextureTarget, TextureInternalFormat, TextureFormat;

        with (TextureBuilder()) {
            width = size[0];
            height = size[1];
            target = TextureTarget.Tex2D;
            mipmapLevel = 0;
            iformat = TextureInternalFormat.Stencil;
            format = TextureFormat.Stencil;

            this.texture = build();
        }
    }

    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearStencil(clear);
    }
}
