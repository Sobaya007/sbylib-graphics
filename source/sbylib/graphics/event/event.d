module sbylib.graphics.event.event;

import sbylib.wrapper.glfw : KeyButton;
import sbylib.graphics.event.eventcontext : EventContext;

interface IEvent {
    void kill();
}

class Event(Args...) : IEvent {
    private void delegate(Args) callback;
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

    override void kill() {
        this.killCondition = () => true;
    }

    package void addFinishCallback(void delegate() finishCallback) {
        this.finishCallbackList ~= finishCallback;
    }
}

Event!(Args) run(Args...)(Event!(Args) event, void delegate(Args) callback) {
    event.callback = callback;
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
