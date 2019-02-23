module sbylib.graphics.event.frameevent;

public import sbylib.graphics.event.event : Event;
import std.typecons : Typedef;

struct Frame_t {
    bool delegate() condition;
}

Frame_t Frame;

alias FrameCallback = void delegate();

class FrameEventWatcher {
static:

    import std.container : Array;

    private Array!FrameCallback callbackList;

    FrameCallback add(FrameCallback callback) {
        this.callbackList ~= callback;
        return callback;
    }

    void remove(FrameCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    void update() {
        for (int i = 0; i < callbackList.length; i++) {
            callbackList[i]();
        }
    }
}

Event when(Frame_t frame) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = FrameEventWatcher.add({
        if (frame.condition && frame.condition() == false) return;
        event.call();
    });
    when(event.finish).run({
        FrameEventWatcher.remove(cb);
    });
    return event;
}
