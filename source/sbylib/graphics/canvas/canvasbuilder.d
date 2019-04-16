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

        auto fb = new Framebuffer;

        auto result = new Canvas(size, fb);

        if (color.enable) {
            auto colorChannel = color.texture ? new ColorChannel(fb, color.texture) : new ColorChannel(fb, size);
            colorChannel.clear = color.clear;
            assert(colorChannel.texture.width == size[0]);
            assert(colorChannel.texture.height == size[1]);

            result.colorChannel = colorChannel;
        }

        if (depth.enable) {
            auto depthChannel = depth.texture ? new DepthChannel(fb, depth.texture) : new DepthChannel(fb, size);
            depthChannel.clear = depth.clear;
            assert(depthChannel.texture.width == size[0]);
            assert(depthChannel.texture.height == size[1]);

            result.depthChannel = depthChannel;
        }

        if (stencil.enable) {
            auto stencilChannel = stencil.texture ? new StencilChannel(fb, stencil.texture) : new StencilChannel(fb, size);
            stencilChannel.clear = stencil.clear;
            assert(stencilChannel.texture.width == size[0]);
            assert(stencilChannel.texture.height == size[1]);

            result.stencilChannel = stencilChannel;
        }

        return result;
    }

    Canvas build(Window window) 
        in (color.texture is null)
        in (depth.texture is null)
        in (stencil.texture is null)
    {

        import sbylib.graphics.canvas.canvaschannel : ColorChannel, DepthChannel, StencilChannel;
        import sbylib.wrapper.gl : DefaultFramebuffer;

        auto colorChannel = new ColorChannel(DefaultFramebuffer, window.size);
        colorChannel.clear = color.clear;

        auto depthChannel = new DepthChannel(DefaultFramebuffer, window.size);
        depthChannel.clear = depth.clear;

        auto stencilChannel = new StencilChannel(DefaultFramebuffer, window.size);
        stencilChannel.clear = stencil.clear;

        if (size == typeof(size).init)
            size = window.size;

        auto result = new Canvas(size, DefaultFramebuffer);
        result.colorChannel = colorChannel;
        result.depthChannel = depthChannel;
        result.stencilChannel = stencilChannel;

        return result;
    }
}

struct ChannelConfig(T) {
    T clear;
    bool enable;
    Texture texture;
}
