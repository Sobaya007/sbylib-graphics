module sbylib.graphics.canvas.canvasbuilder;

public import sbylib.graphics.canvas.canvas : Canvas;
public import sbylib.graphics.util.color : Color;
public import sbylib.wrapper.gl : Texture;
public import sbylib.wrapper.glfw : Window;

struct CanvasBuilder {
    int[2] size;
    ChannelConfig!Color color = ChannelConfig!Color(Color.Black, true);
    ChannelConfig!float depth = ChannelConfig!float(1, false);
    ChannelConfig!int stencil = ChannelConfig!int(0, false);

    Canvas build() {

        import sbylib.graphics.canvas.canvaschannel : ColorChannel, DepthChannel, StencilChannel;
        import sbylib.wrapper.gl : Framebuffer;

        ColorChannel colorChannel;
        DepthChannel depthChannel;
        StencilChannel stencilChannel;

        if (color.enable) {
            colorChannel = color.texture ? new ColorChannel(color.texture) : new ColorChannel(size);
            colorChannel.clear = color.clear;
            assert(colorChannel.texture.width == size[0]);
            assert(colorChannel.texture.height == size[1]);
        }

        if (depth.enable) {
            depthChannel = depth.texture ? new DepthChannel(depth.texture) : new DepthChannel(size);
            depthChannel.clear = depth.clear;
            assert(depthChannel.texture.width == size[0]);
            assert(depthChannel.texture.height == size[1]);
        }

        if (stencil.enable) {
            stencilChannel = stencil.texture ? new StencilChannel(stencil.texture) : new StencilChannel(size);
            stencilChannel.clear = stencil.clear;
            assert(stencilChannel.texture.width == size[0]);
            assert(stencilChannel.texture.height == size[1]);
        }

        return new Canvas(size, colorChannel, depthChannel, stencilChannel, new Framebuffer);
    }

    Canvas build(Window window) 
        in (color.texture is null)
        in (depth.texture is null)
        in (stencil.texture is null)
    {

        import sbylib.graphics.canvas.canvaschannel : ColorChannel, DepthChannel, StencilChannel;
        import sbylib.wrapper.gl : DefaultFramebuffer;

        auto colorChannel = new ColorChannel(window.size);
        colorChannel.clear = color.clear;

        auto depthChannel = new DepthChannel(window.size);
        depthChannel.clear = depth.clear;

        auto stencilChannel = new StencilChannel(window.size);
        stencilChannel.clear = stencil.clear;

        if (size == typeof(size).init)
            size = window.size;

        return new Canvas(size, colorChannel, depthChannel, stencilChannel, DefaultFramebuffer);
    }
}

struct ChannelConfig(T) {
    T clear;
    bool enable;
    Texture texture;
}
