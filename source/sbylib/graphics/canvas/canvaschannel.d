module sbylib.graphics.canvas.canvaschannel;

public import sbylib.math : vec4;
public import sbylib.graphics.util.color : Color;
public import sbylib.wrapper.gl : Texture, TextureTarget, TextureInternalFormat, FramebufferAttachType, TextureFormat;
import sbylib.wrapper.gl : Framebuffer;
import std.algorithm : among;

private mixin template ImplChannel(TextureInternalFormat InternalFormat, TextureFormat Format, FramebufferAttachType AttachType) {
    Texture texture;

    private Framebuffer fb;

    this(Framebuffer fb, Texture texture) 
        in (texture.target == TextureTarget.Tex2D)
    {
        this.fb = fb;
        this.attach(texture);
    }

    this(Framebuffer fb, int[2] size) {
        import sbylib.wrapper.gl : Texture, TextureBuilder, TextureTarget, TextureInternalFormat, TextureFormat;

        with (TextureBuilder()) {
            width = size[0];
            height = size[1];
            target = TextureTarget.Tex2D;
            mipmapLevel = 0;
            iformat = InternalFormat;
            format = Format;

            this(fb, build());
        }
    }

    void destroy() {
        this.texture.destroy();
    }

    void attach(Texture texture) 
        in (texture !is null)
    {
        this.texture = texture;
        this.fb.attach(texture, 0, AttachType);
    }
}

class ColorChannel {

    mixin ImplChannel!(TextureInternalFormat.RGBA32F, TextureFormat.RGBA, FramebufferAttachType.Color0);

    Color clear = Color.Black;

    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearColor(clear.r, clear.g, clear.b, clear.a);
    }
}

class DepthChannel {

    mixin ImplChannel!(TextureInternalFormat.Depth, TextureFormat.Depth, FramebufferAttachType.Depth);

    float clear = 1;


    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearDepth(clear);
    }
}

class StencilChannel {

    mixin ImplChannel!(TextureInternalFormat.Stencil, TextureFormat.Stencil, FramebufferAttachType.Stencil);
    
    int clear = 0;

    void clearSetting() {
        import sbylib.wrapper.gl : GlFunction;

        GlFunction.clearStencil(clear);
    }
}
