module sbylib.graphics.renderable;

import std.container : Array;
import sbylib.graphics.event : Event;

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

Event when(RenderCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    RenderCallback cb;
    cb = condition.renderable.add({
        event.call();
    });
    when(event.finish).run({
        condition.renderable.remove(cb);
    });
    return event;
}
