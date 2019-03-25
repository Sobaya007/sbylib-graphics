module sbylib.graphics.event.event;

import sbylib.wrapper.glfw : KeyButton;
import sbylib.graphics.event.eventcontext : EventContext;

interface IEvent {
    void kill();
}

class Event(Args...) : IEvent {
    private void delegate(Args) callback;
    private void delegate(Exception) onerror;
    private bool delegate() killCondition;
    private void delegate()[] finishCallbackList;
    package EventContext context;
    private bool alive = true;

    this() {
        context = EventContext.currentContext;
        if (context)
            context.eventList ~= this;
    }

    void fire(Args args) 
    {
        if (!alive) return;
        if (killCondition && killCondition()) {
            this.alive = false;
            foreach (cb; finishCallbackList) cb();
            return;
        }
        if (context && !context.isBound()) return;
        if (callback) callback(args);
    }

    void throwError(Exception e) {
        if (onerror) onerror(e);
        else throw e;
    }

    override void kill() {
        this.killCondition = () => true;
    }

    package void addFinishCallback(void delegate() finishCallback) {
        this.finishCallbackList ~= finishCallback;
    }
}

Event!(Args) then(Args...)(Event!(Args) event, void delegate(Args) callback) {
    event.callback = callback;
    return event;
}

Event!(Args) error(Args...)(Event!(Args) event, void delegate(Exception) callback) {
    event.onerror = callback;
    return event;
}

Event!(Args) until(Args...)(Event!(Args) event, bool delegate() condition) {
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
