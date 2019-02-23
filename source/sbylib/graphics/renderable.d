module sbylib.graphics.renderable;

import std.container : Array;
import sbylib.graphics.event : Event;

alias RenderCallback = void delegate();

struct RenderCondition {
    Renderable renderable;
}

abstract class Renderable {
    protected Array!(RenderCallback) renderCallbackList;

    abstract void renderImpl();

    final void render() {
        foreach (cb; renderCallbackList) {
            cb();
        }
        renderImpl();
    }

    RenderCondition beforeRender() {
        return RenderCondition(this);
    }

    package RenderCallback add(RenderCallback cb) {
        renderCallbackList ~= cb;
        return cb;
    }

    package void remove(RenderCallback cb) {
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
