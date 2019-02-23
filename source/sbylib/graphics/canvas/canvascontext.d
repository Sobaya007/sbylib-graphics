module sbylib.graphics.canvas.canvascontext;

public import sbylib.wrapper.gl : ClearMode;
public import sbylib.graphics.canvas.canvas : Canvas;
import sbylib.wrapper.gl : Framebuffer;
import std.container : Stack = Array;

struct CanvasContext {
    private static Stack!Canvas _canvasStack;
    private Canvas _canvas;

    this(Canvas _canvas) {
        import sbylib.wrapper.glfw : Window;
        import sbylib.graphics.canvas.canvasbuilder : CanvasBuilder;

        this._canvas = _canvas;

        if (_canvasStack.empty) _canvasStack.insertBack(CanvasBuilder().build(Window.getCurrentWindow()));
        _canvasStack.insertBack(_canvas);
        _canvas.bind();
    }

    ~this() {
        _canvasStack.removeBack();
        _canvasStack.back.bind();
    }

    void clear(ClearMode[] mode...) {
        this._canvas.clear(mode);
    }
}

CanvasContext getContext(Canvas canvas) {
    return CanvasContext(canvas);
}
