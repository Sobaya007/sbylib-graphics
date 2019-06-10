module sbylib.graphics.event.eventcontext;

import sbylib.graphics.event.event : IEvent, VoidEvent;
import std.container : Array;

private alias BindCallback = void delegate();
private struct BindNotification { EventContext context; bool bind; }

class EventContext {

    package static EventContext[] currentContext;

    private Array!BindCallback bindCallbackList;
    private Array!BindCallback unbindCallbackList;
    package Array!IEvent eventList;
    private bool _bound = false;

    private static int seed = 0;

    int id;

    this() {
        this.id = seed++;
    }

    ~this() {
        kill();
    }

    void kill() {
        foreach (e; eventList) {
            e.kill();
        }
    }

    void bind() {
        _bound = true;
        foreach (cb; bindCallbackList) cb();
    }

    void unbind() {
        _bound = false;
        foreach (cb; unbindCallbackList) cb();
    }

    bool isBound() {
        return _bound;
    }

    ContextRegister opCall() {
        currentContext ~= this;
        return ContextRegister();
    }

    BindNotification bound() {
        return BindNotification(this, true);
    }

    BindNotification unbound() {
        return BindNotification(this, false);
    }

    private BindCallback add(BindCallback callback, bool bind) {
        if (callback) {
            if (bind) bindCallbackList ~= callback;
            else unbindCallbackList ~= callback;
        }
        return callback;
    }

    private void remove(BindCallback callback, bool bind) {
        import std.algorithm : find;
        import std.range : take;

        if (bind) {
            bindCallbackList.linearRemove(bindCallbackList[].find(callback).take(1));
        } else {
            unbindCallbackList.linearRemove(unbindCallbackList[].find(callback).take(1));
        }
    }
}

VoidEvent when(BindNotification condition) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = condition.context.add({ event.fire(); }, condition.bind);
    when(event.finish).then({
        condition.context.remove(cb, condition.bind);
    });
    return event;
}

private struct ContextRegister {

    ~this() {
        import std : popBack;

        EventContext.currentContext.popBack;
    }
}
