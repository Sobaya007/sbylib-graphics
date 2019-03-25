module sbylib.graphics.event.frameevent;

public import sbylib.graphics.event.event : VoidEvent;
import std.typecons : Typedef;
import std.container : Array;

private alias FrameCallback = void delegate();

struct FrameNotification { private bool delegate() condition; }

FrameNotification Frame;

VoidEvent when(FrameNotification frame) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = FrameEventWatcher.add({
        if (frame.condition && frame.condition() == false) return;
        event.fire();
    });
    when(event.finish).then({
        FrameEventWatcher.remove(cb);
    });
    return event;
}

class FrameEventWatcher {
static:

    private Array!FrameCallback callbackList;

    private FrameCallback add(FrameCallback callback) {
        this.callbackList ~= callback;
        return callback;
    }

    private void remove(FrameCallback callback) {
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
