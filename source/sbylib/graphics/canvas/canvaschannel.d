module sbylib.graphics.canvas.canvaschannel;

public import sbylib.math : vec4;
public import sbylib.graphics.util.color : Color;
public import sbylib.wrapper.gl : Texture, TextureTarget, TextureInternalFormat, FramebufferAttachType;
import std.algorithm : among;

class ColorChannel {

    enum AttachType = FramebufferAttachType.Color0;

    Texture texture;
    Color clear = Color.Black;

    this(Texture texture) 
        in (texture.target == TextureTarget.Tex2D)
        in (!texture.internalFormat.among(TextureInternalFormat.Depth, TextureInternalFormat.Stencil))
    {
        this.texture = texture;
    }

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

    void destroy() {
        this.texture.destroy();
    }
}

class DepthChannel {

    enum AttachType = FramebufferAttachType.Depth;
    
    Texture texture;
    float clear = 1;

    this(Texture texture) 
        in (texture.target == TextureTarget.Tex2D)
        in (texture.internalFormat == TextureInternalFormat.Depth)
    {
        this.texture = texture;
    }

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

    void destroy() {
        this.texture.destroy();
    }
}

class StencilChannel {
    
    enum AttachType = FramebufferAttachType.Stencil;

    Texture texture;
    int clear = 0;

    this(Texture texture) 
        in (texture.target == TextureTarget.Tex2D)
        in (texture.internalFormat == TextureInternalFormat.Stencil)
    {
        this.texture = texture;
    }

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

    void destroy() {
        this.texture.destroy();
    }
}
