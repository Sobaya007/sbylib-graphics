module sbylib.graphics.event.event;

public import sbylib.wrapper.glfw : KeyButton;
public import sbylib.graphics.event.eventcontext : EventContext;

alias Condition = bool delegate();
alias Callback = void delegate();

class Event {
    private void delegate() callback;
    private bool delegate() killCondition;
    private void delegate()[] finishCallbackList;
    package EventContext context;
    private debug bool alive = true;

    this() {
        context = EventContext.currentContext;
    }

    void call() 
        in (alive)
    {
        if (killCondition && killCondition()) {
            this.alive = false;
            foreach (cb; finishCallbackList) cb();
            return;
        }
        if (context && !context.isBound()) return;
        if (callback) callback();
    }

    package void addFinishCallback(void delegate() finishCallback) {
        this.finishCallbackList ~= finishCallback;
    }
}

Event run(Event event, void delegate() callback) {
    event.callback = callback;
    return event;
}

deprecated Event run(Event event, lazy void callback) { // this makes segmentation fault
    event.callback = () => callback;
    return event;
}

Event until(Event event, bool delegate() condition) {
    event.killCondition = condition;
    return event;
}

deprecated Event until(Event event, lazy bool condition) { // this makes segmentation fault
    event.until(() => condition);
    return event;
}
