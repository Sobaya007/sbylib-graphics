module sbylib.graphics.event.eventcontext;

public import sbylib.graphics.event.event : Event;
import std.container : Array;

private alias BindCallback = void delegate();
private struct BindCondition { EventContext context; bool bind; }

class EventContext {

    package static EventContext currentContext;

    private Array!BindCallback bindCallbackList;
    private Array!BindCallback unbindCallbackList;
    private bool _bound = false;

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

    ContextRegister opCall() 
        in(currentContext is null)
    {
        currentContext = this;
        return ContextRegister();
    }

    BindCondition bound() {
        return BindCondition(this, true);
    }

    BindCondition unbound() {
        return BindCondition(this, false);
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

Event when(BindCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = condition.context.add({ event.call(); }, condition.bind);
    when(event.finish).run({
        condition.context.remove(cb, condition.bind);
    });
    return event;
}

private struct ContextRegister {

    ~this() {
        EventContext.currentContext = null;
    }
}
