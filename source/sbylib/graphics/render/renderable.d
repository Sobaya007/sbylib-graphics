module sbylib.graphics.render.renderable;

import std.container : Array;
import sbylib.event : VoidEvent;

private alias RenderCallback = void delegate();
private struct RenderCondition { Renderable renderable; }

abstract class Renderable {
    protected Array!(RenderCallback) renderCallbackList;

    protected abstract void renderImpl();

    final void render() {
        foreach (cb; renderCallbackList) {
            cb();
        }
        renderImpl();
    }

    RenderCondition beforeRender() {
        return RenderCondition(this);
    }

    private RenderCallback add(RenderCallback cb) {
        renderCallbackList ~= cb;
        return cb;
    }

    private void remove(RenderCallback cb) {
        import std.algorithm : find;
        import std.range : take;

        renderCallbackList.linearRemove(renderCallbackList[].find(cb).take(1));
    }
}

VoidEvent when(RenderCondition condition) {
    import sbylib.event : when, finish, then;

    auto event = new VoidEvent;
    RenderCallback cb;
    cb = condition.renderable.add({
        event.fire();
    });
    when(event.finish).then({
        condition.renderable.remove(cb);
    });
    return event;
}
