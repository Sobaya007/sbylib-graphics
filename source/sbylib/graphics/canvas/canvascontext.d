module sbylib.graphics.canvas.canvascontext;

public import sbylib.wrapper.gl : ClearMode;
public import sbylib.graphics.canvas.canvas : Canvas;
import sbylib.wrapper.gl : Framebuffer;
import std.container : Stack = Array;

struct CanvasContext {
    private static Stack!Canvas canvasStack;
    private Canvas canvas;

    this(Canvas canvas) {
        import sbylib.wrapper.glfw : Window;
        import sbylib.graphics.canvas.canvasbuilder : CanvasBuilder;

        this.canvas = canvas;

        if (canvasStack.empty) canvasStack.insertBack(CanvasBuilder().build(Window.getCurrentWindow()));
        canvasStack.insertBack(canvas);
        canvas.bind();
    }

    ~this() {
        canvasStack.removeBack();
        canvasStack.back.bind();
    }

    void clear(ClearMode[] mode...) {
        this.canvas.clear(mode);
    }
}

CanvasContext getContext(Canvas canvas) {
    return CanvasContext(canvas);
}
