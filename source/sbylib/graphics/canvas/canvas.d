module sbylib.graphics.canvas.canvas;
public import sbylib.graphics.render.renderable : Renderable;
public import sbylib.wrapper.gl : ClearMode, Framebuffer, TextureFilter, BufferBit;

import sbylib.graphics.canvas.canvaschannel : ColorChannel, DepthChannel, StencilChannel;

class Canvas {

    package Framebuffer fb;
    package ColorChannel colorChannel;
    package DepthChannel depthChannel;
    package StencilChannel stencilChannel;
    package debug bool hasCleared;
    private int[2] _size;

    this(int[2] size, Framebuffer fb) {
        this._size = size;
        this.fb = fb;
    }

    void destroy() {
        if (fb) this.fb.destroy();
        if (colorChannel) this.colorChannel.destroy();
        if (depthChannel) this.depthChannel.destroy();
        if (stencilChannel) this.stencilChannel.destroy();
    }

    package void clear(ClearMode[] mode...) {
        import sbylib.wrapper.gl : GlUtils;

        if (colorChannel) colorChannel.clearSetting();
        if (depthChannel) depthChannel.clearSetting();
        if (stencilChannel) stencilChannel.clearSetting();
        GlUtils().clear(mode);

        debug hasCleared = true;
    }

    void render(Canvas canvas,
            int srcX0, int srcY0, int srcX1, int srcY1, 
            int dstX0, int dstY0, int dstX1, int dstY1,
            TextureFilter filter, BufferBit[] bit...) {
        this.fb.blitsTo(canvas.fb,
                srcX0, srcY0, srcX1, srcY1, 
                dstX0, dstY0, dstX1, dstY1, 
                filter, bit);
    }

    package void bind() {
        import sbylib.wrapper.gl : FramebufferBindType, GlFunction;
        fb.bind(FramebufferBindType.Write);
        GlFunction().setViewport(0,0,size[0],size[1]);
    }

    ColorChannel color() { return colorChannel; }
    DepthChannel depth() { return depthChannel; }
    StencilChannel stencil() { return stencilChannel; }
    int[2] size() { return _size; }
}
