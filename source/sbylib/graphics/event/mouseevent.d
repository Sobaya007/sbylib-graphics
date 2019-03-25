module sbylib.graphics.event.mouseevent;

public import sbylib.wrapper.glfw : MouseButton, ButtonState, ModKeyButton;
public import sbylib.math : vec2;

import sbylib.graphics.event.event : VoidEvent;
import sbylib.wrapper.glfw : Window;
import std.container : Array;
import std.typecons : BitFlags;

private alias MouseEnterCallback = void delegate(Window, bool);
private alias MousePosCallback = void delegate(Window, double[2]);
private alias MouseButtonCallback = void delegate(Window, MouseButton, ButtonState, BitFlags!ModKeyButton);

private struct MouseEnterNotification {}
private struct MouseLeaveNotification {}
private struct MousePosNotification {}
private struct MouseButtonNotification {
    MouseButton button;
    ButtonState state;
}

private struct Mouse {
    MouseEnterNotification entered() { return MouseEnterNotification(); }
    MouseLeaveNotification left() { return MouseLeaveNotification(); }
    MousePosNotification moved() { return MousePosNotification(); }
    vec2 pos() { return vec2(Window.getCurrentWindow().mousePos); }
}

Mouse mouse() { return Mouse(); }

MouseButtonNotification pressed(MouseButton mouse) {
    return MouseButtonNotification(mouse, ButtonState.Press);
}

MouseButtonNotification released(MouseButton mouse) {
    return MouseButtonNotification(mouse, ButtonState.Release);
}

auto pressing(MouseButton mouse) {
    import sbylib.graphics.event.frameevent : FrameNotification;
    return FrameNotification(() => Window.getCurrentWindow().getMouse(mouse) == ButtonState.Press);
}

VoidEvent when(MouseEnterNotification condition) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = MouseEventWatcher.add((Window, bool entered) {
        if (!entered) return;
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

VoidEvent when(MouseLeaveNotification condition) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = MouseEventWatcher.add((Window, bool entered) {
        if (entered) return;
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

VoidEvent when(MousePosNotification condition) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = MouseEventWatcher.add((Window, double[2]) {
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

VoidEvent when(MouseButtonNotification condition) {
    import sbylib.graphics.event : when, finish, then;

    auto event = new VoidEvent;
    auto cb = MouseEventWatcher.add((Window, MouseButton button, ButtonState state, BitFlags!ModKeyButton) {
        if (button != condition.button) return;
        if (state != condition.state) return;
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(cb);
    });
    return event;
}

private class MouseEventWatcher {
static:
    private Array!MouseEnterCallback enterCallbackList;
    private Array!MousePosCallback posCallbackList;
    private Array!MouseButtonCallback buttonCallbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;

        alias errorHandler = (Exception e) { assert(false, e.toString()); };
        Window.getCurrentWindow().setMouseEnterCallback!(enterCallback, errorHandler);
        Window.getCurrentWindow().setMousePosCallback!(posCallback, errorHandler);
        Window.getCurrentWindow().setMouseButtonCallback!(buttonCallback, errorHandler);
    }

    private MouseEnterCallback add(MouseEnterCallback callback) {
        use();
        enterCallbackList ~= callback;
        return callback;
    }

    private void remove(MouseEnterCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        enterCallbackList.linearRemove(enterCallbackList[].find(callback).take(1));
    }

    void enterCallback(Window window, bool enter) {
        foreach (cb; enterCallbackList) {
            cb(window, enter);
        }
    }

    private MousePosCallback add(MousePosCallback callback) {
        use();
        posCallbackList ~= callback;
        return callback;
    }

    private void remove(MousePosCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        posCallbackList.linearRemove(posCallbackList[].find(callback).take(1));
    }

    void posCallback(Window window, double[2] pos) {
        foreach (cb; posCallbackList) {
            cb(window, pos);
        }
    }

    private MouseButtonCallback add(MouseButtonCallback callback) {
        use();
        buttonCallbackList ~= callback;
        return callback;
    }

    private void remove(MouseButtonCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        buttonCallbackList.linearRemove(buttonCallbackList[].find(callback).take(1));
    }

    void buttonCallback(Window window, MouseButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (cb; buttonCallbackList) {
            cb(window, button, state, mods);
        }
    }
}
