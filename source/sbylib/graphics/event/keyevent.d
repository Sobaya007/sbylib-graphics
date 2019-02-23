module sbylib.graphics.event.keyevent;
public import sbylib.wrapper.glfw : KeyButton, ButtonState, ModKeyButton;
import sbylib.graphics.event.event : Condition, Event;
import sbylib.wrapper.glfw : Window;
import std.container : Array;
import std.typecons : BitFlags;

private alias KeyCallback = void delegate(Window, KeyButton, int, ButtonState, BitFlags!ModKeyButton);

private struct KeyCondition {
    KeyButton button;
    ButtonState state;
}

KeyCondition pressed(KeyButton key) {
    return KeyCondition(key, ButtonState.Press);
}

KeyCondition released(KeyButton key) {
    return KeyCondition(key, ButtonState.Release);
}

auto pressing(KeyButton key) {
    import sbylib.graphics.event.frameevent : Frame_t;
    return Frame_t(() => Window.getCurrentWindow().getKey(key) == ButtonState.Press);
}

Event when(KeyCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = KeyEventWatcher.add((Window, KeyButton button, int, ButtonState state, BitFlags!ModKeyButton) {
        if (button != condition.button) return;
        if (state != condition.state) return;
        event.call();
    });
    when(event.finish).run({
        KeyEventWatcher.remove(cb);
    });
    return event;
}

class KeyEventWatcher {
static:
    private Array!KeyCallback callbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;
        Window.getCurrentWindow().setKeyCallback!(keyCallback);
    }

    KeyCallback add(KeyCallback callback) {
        use();
        callbackList ~= callback;
        return callback;
    }

    void remove(KeyCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    void keyCallback(Window window, KeyButton button, int scanCode, ButtonState state, BitFlags!ModKeyButton mods) nothrow {
        try {
            foreach (cb; callbackList) {
                cb(window, button, scanCode, state, mods);
            }
        } catch (Throwable e) {
            assert(false, e.toString);
        }
    }
}
