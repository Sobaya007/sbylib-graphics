module sbylib.graphics.event.event;

import sbylib.wrapper.glfw : KeyButton;
import sbylib.graphics.event.eventcontext : EventContext;

interface IEvent {
    void kill();
    void addFinishCallback(void delegate());
    bool isAlive() const;
    EventContext[] context();
}

class Event(Args...) : IEvent {
    import std.container : Array;

    private void delegate(Args) callback;
    private void delegate(Exception) onerror;
    private bool delegate() killCondition;
    private void delegate()[] finishCallbackList;
    package EventContext[] _context;
    private bool alive = true;

    this() {
        _context = EventContext.currentContext;
        foreach (c; context) {
            c.eventList ~= this;
        }
        EventWatcher._eventList ~= this;
    }

    void fire(Args args) {
        import std.algorithm : any;

        if (this.isAlive is false) return;
        if (killCondition && killCondition()) {
            this.alive = false;
            foreach (cb; finishCallbackList) cb();
            return;
        }
        if (context.any!(c => c.isBound is false)) return;
        if (callback) callback(args);
    }

    void fireOnce(Args args) {
        this.fire(args);
        this.kill();
        this.fire(args); // for launch finish callback
    }

    void throwError(Exception e) {
        this.kill();
        if (onerror) onerror(e);
        else throw e;
    }

    override bool isAlive() const {
        return alive;
    }

    override void kill() {
        this.killCondition = () => true;
    }

    override void addFinishCallback(void delegate() finishCallback) {
        if (this.isAlive) {
            this.finishCallbackList ~= finishCallback;
        } else {
            finishCallback();
        }
    }

    override EventContext[] context() {
        return _context;
    }
}

Event!(Args) then(Args...)(Event!(Args) event, void delegate() callback) 
    if (Args.length > 0)
{
    assert(event.callback is null);
    event.callback = (Args _) { callback(); };
    return event;
}

Event!(Args) then(Args...)(Event!(Args) event, void delegate(Args) callback) {
    assert(event.callback is null);
    event.callback = callback;
    return event;
}

Event!(Args) error(Args...)(Event!(Args) event, void delegate(Exception) callback) {
    assert(event.onerror is null);
    event.onerror = callback;
    return event;
}

Event!(Args) until(Args...)(Event!(Args) event, bool delegate() condition) {
    assert(event.killCondition is null);
    event.killCondition = condition;
    return event;
}

Event!(Args) once(Args...)(Event!(Args) event) {
    bool hasRun;
    event.killCondition = {
        if (hasRun) return true;
        hasRun = true;
        return false;
    };
    return event;
}

alias VoidEvent = Event!();

class EventWatcher {
static:

    import std : Array;

    Array!IEvent _eventList;

    void update() {
        import std : find;
        _eventList.linearRemove(_eventList[].find!(e => !e.isAlive));
    }

    const(Array!IEvent) eventList() {
        return _eventList;
    }

}
