module sbylib.graphics.event.charevent;
import sbylib.graphics.event.event : Event;
import sbylib.wrapper.glfw : Window;
import std.container : Array;

private alias CharCallback = void delegate(Window, uint);

private struct CharNotification {}
private struct Key_t {}

Key_t Key() {
    return Key_t();
}

CharNotification pressed(Key_t) {
    return CharNotification();
}

Event!(uint) when(CharNotification condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event!(uint);
    auto cb = CharEventWatcher.add((Window, uint codepoint) {
        event.fire(codepoint);
    });
    when(event.finish).run({
        CharEventWatcher.remove(cb);
    });
    return event;
}

private class CharEventWatcher {
static:
    private Array!CharCallback callbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;
        Window.getCurrentWindow().setCharCallback!(charCallback, (Exception e) { assert(false, e.toString()); });
    }

    private CharCallback add(CharCallback callback) {
        use();
        callbackList ~= callback;
        return callback;
    }

    private void remove(CharCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    void charCallback(Window window, uint codepoint) {
        foreach (cb; callbackList) {
            cb(window, codepoint);
        }
    }
}
