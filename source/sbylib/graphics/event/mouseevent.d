module sbylib.graphics.event.mouseevent;

public import sbylib.wrapper.glfw : MouseButton, ButtonState, ModKeyButton;
public import sbylib.math : vec2;

import sbylib.graphics.event.event : Condition, Event;
import sbylib.wrapper.glfw : Window;
import std.container : Array;
import std.typecons : BitFlags;

private alias MouseEnterCallback = void delegate(Window, bool);
private alias MousePosCallback = void delegate(Window, double[2]);
private alias MouseButtonCallback = void delegate(Window, MouseButton, ButtonState, BitFlags!ModKeyButton);

private struct MouseEnterCondition {}
private struct MouseLeaveCondition {}
private struct MousePosCondition {}
private struct MouseButtonCondition {
    MouseButton button;
    ButtonState state;
}

private struct Mouse {
    MouseEnterCondition entered() { return MouseEnterCondition(); }
    MouseLeaveCondition left() { return MouseLeaveCondition(); }
    MousePosCondition moved() { return MousePosCondition(); }
    vec2 pos() { return vec2(Window.getCurrentWindow().mousePos); }
}

Mouse mouse() { return Mouse(); }

MouseButtonCondition pressed(MouseButton mouse) {
    return MouseButtonCondition(mouse, ButtonState.Press);
}

MouseButtonCondition released(MouseButton mouse) {
    return MouseButtonCondition(mouse, ButtonState.Release);
}

auto pressing(MouseButton mouse) {
    import sbylib.graphics.event.frameevent : Frame_t;
    return Frame_t(() => Window.getCurrentWindow().getMouse(mouse) == ButtonState.Press);
}

Event when(MouseEnterCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = MouseEventWatcher.add((Window, bool entered) {
        if (!entered) return;
        event.call();
    });
    when(event.finish).run({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

Event when(MouseLeaveCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = MouseEventWatcher.add((Window, bool entered) {
        if (entered) return;
        event.call();
    });
    when(event.finish).run({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

Event when(MousePosCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = MouseEventWatcher.add((Window, double[2]) {
        event.call();
    });
    when(event.finish).run({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

Event when(MouseButtonCondition condition) {
    import sbylib.graphics.event : when, finish, run;

    auto event = new Event;
    auto cb = MouseEventWatcher.add((Window, MouseButton button, ButtonState state, BitFlags!ModKeyButton) {
        if (button != condition.button) return;
        if (state != condition.state) return;
        event.call();
    });
    when(event.finish).run({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

class MouseEventWatcher {
static:
    private Array!MouseEnterCallback enterCallbackList;
    private Array!MousePosCallback posCallbackList;
    private Array!MouseButtonCallback buttonCallbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;
        Window.getCurrentWindow().setMouseEnterCallback!(enterCallback);
        Window.getCurrentWindow().setMousePosCallback!(posCallback);
        Window.getCurrentWindow().setMouseButtonCallback!(buttonCallback);
    }

    MouseEnterCallback add(MouseEnterCallback callback) {
        use();
        enterCallbackList ~= callback;
        return callback;
    }

    void remove(MouseEnterCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        enterCallbackList.linearRemove(enterCallbackList[].find(callback).take(1));
    }

    void enterCallback(Window window, bool enter) nothrow {
        try {
            foreach (cb; enterCallbackList) {
                cb(window, enter);
            }
        } catch (Throwable e) {
            assert(false, e.toString);
        }
    }

    MousePosCallback add(MousePosCallback callback) {
        use();
        posCallbackList ~= callback;
        return callback;
    }

    void remove(MousePosCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        posCallbackList.linearRemove(posCallbackList[].find(callback).take(1));
    }

    void posCallback(Window window, double[2] pos) nothrow {
        try {
            foreach (cb; posCallbackList) {
                cb(window, pos);
            }
        } catch (Throwable e) {
            assert(false, e.toString);
        }
    }

    MouseButtonCallback add(MouseButtonCallback callback) {
        use();
        buttonCallbackList ~= callback;
        return callback;
    }

    void remove(MouseButtonCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        buttonCallbackList.linearRemove(buttonCallbackList[].find(callback).take(1));
    }

    void buttonCallback(Window window, MouseButton button, ButtonState state, BitFlags!ModKeyButton mods) nothrow {
        try {
            foreach (cb; buttonCallbackList) {
                cb(window, button, state, mods);
            }
        } catch (Throwable e) {
            assert(false, e.toString);
        }
    }
}
