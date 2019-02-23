module sbylib.graphics.canvas.canvasbuilder;

public import sbylib.graphics.canvas.canvas : Canvas;
public import sbylib.graphics.util.color : Color;
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
            colorChannel = new ColorChannel(size);
            colorChannel.clear = color.clear;
        }

        if (depth.enable) {
            depthChannel = new DepthChannel(size);
            depthChannel.clear = depth.clear;
        }

        if (stencil.enable) {
            stencilChannel = new StencilChannel(size);
            stencilChannel.clear = stencil.clear;
        }

        return new Canvas(size, colorChannel, depthChannel, stencilChannel, new Framebuffer);
    }

    Canvas build(Window window) {

        import sbylib.graphics.canvas.canvaschannel : ColorChannel, DepthChannel, StencilChannel;
        import sbylib.wrapper.gl : DefaultFramebuffer;

        auto colorChannel = new ColorChannel(window.size);
        colorChannel.clear = color.clear;

        auto depthChannel = new DepthChannel(window.size);
        depthChannel.clear = depth.clear;

        auto stencilChannel = new StencilChannel(window.size);
        stencilChannel.clear = stencil.clear;

        return new Canvas(window.size, colorChannel, depthChannel, stencilChannel, DefaultFramebuffer);
    }
}

struct ChannelConfig(T) {
    T clear;
    bool enable;
}
