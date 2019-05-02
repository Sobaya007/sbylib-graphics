module sbylib.graphics.event.keyevent;

public import sbylib.wrapper.glfw : KeyButton, ButtonState, ModKeyButton;
import sbylib.graphics.event.event : VoidEvent;
import sbylib.wrapper.glfw : Window;
import std.container : Array;
import std.typecons : BitFlags, Nullable, nullable;
import std.meta : AliasSeq;

private alias KeyCallback = void delegate(Window, KeyButton, int, ButtonState, BitFlags!ModKeyButton);

private struct KeyButtonWithSpecial {
    Nullable!KeyButton button;
    bool[ModKeyButton] mod;

    this(KeyButton button) {
        this.button = button;
    }

    this(ModKeyButton button) {
        this.mod[button] = true;
    }

    this(KeyButton button, bool[ModKeyButton] mod) {
        this.button = button;
        this.mod = mod;
    }

    this(Nullable!KeyButton button, bool[ModKeyButton] mod) {
        this.button = button;
        this.mod = mod;
    }

    KeyButtonWithSpecial opBinary(string op)(KeyButton key) 
        if (op == "+")
    {
        return KeyButtonWithSpecial(key, this.mod);
    }

    KeyButtonWithSpecial opBinary(string op)(KeyButtonWithSpecial key) 
        if (op == "+")
        in (this.button.isNull || key.button.isNull)
    {
        auto mod = this.mod;
        foreach (modKey, value; key.mod) mod[modKey] = true;

        auto button = this.button;
        if (!key.button.isNull) button = nullable(key.button);
        return KeyButtonWithSpecial(button, mod);
    }
}

KeyButtonWithSpecial Ctrl() {
    return KeyButtonWithSpecial(ModKeyButton.Control);
}

KeyButtonWithSpecial Shift() {
    return KeyButtonWithSpecial(ModKeyButton.Shift);
}

KeyButtonWithSpecial Alt() {
    return KeyButtonWithSpecial(ModKeyButton.Alt);
}

KeyButtonWithSpecial Super() {
    return KeyButtonWithSpecial(ModKeyButton.Super);
}

private struct KeyNotification {
    KeyButtonWithSpecial button;
    ButtonState state; 

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        if (button != this.button.button) return false;
        if (state != this.state) return false;
        foreach (key, value; this.button.mod) {
            if (value && !(mods & key)) return false;
        }
        return true;
    }
}

private struct OrKeyNotification {
    KeyNotification[] keys;

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (key; keys) {
            if (key.judge(button, state, mods)) return true;
        }
        return false;
    }
}

OrKeyNotification or(KeyNotification[] keys...) {
    typeof(return) result;
    foreach (key; keys)
        result.keys ~= key;
    return result;
}

private struct AndKeyNotification {
    KeyNotification[] keys;

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (key; keys) {
            if (!key.judge(button, state, mods)) return false;
        }
        return true;
    }
}

AndKeyNotification and(KeyNotification[] keys...) {
    typeof(return) result;
    foreach (key; keys)
        result.keys ~= key;
    return result;
}

KeyNotification pressed(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Press);
}

KeyNotification pressed(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Press);
}

KeyNotification repeated(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Repeat);
}

KeyNotification repeated(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Repeat);
}

KeyNotification released(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Release);
}

KeyNotification released(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Release);
}

auto pressing(KeyButton key) {
    import sbylib.graphics.event.frameevent : FrameNotification;
    return FrameNotification(() => Window.getCurrentWindow().getKey(key) == ButtonState.Press);
}

auto releasing(KeyButton key) {
    import sbylib.graphics.event.frameevent : FrameNotification;
    return FrameNotification(() => Window.getCurrentWindow().getKey(key) == ButtonState.Release);
}

static foreach (NotificationType; AliasSeq!(KeyNotification, OrKeyNotification, AndKeyNotification)) {
    VoidEvent when(NotificationType condition) {
        import sbylib.graphics.event : when, finish, then;
    
        auto event = new VoidEvent;
        auto cb = KeyEventWatcher.add((Window, KeyButton button, int, ButtonState state, BitFlags!ModKeyButton mods) {
            if (condition.judge(button, state, mods)) event.fire();
        });
        when(event.finish).then({ KeyEventWatcher.remove(cb); });
        return event;
    }
}

private struct AnyKey {}

AnyKey Key() {
    return AnyKey();
}

private struct AnyKeyNotification {
    ButtonState state; 
}

AnyKeyNotification pressed(AnyKey key) {
    return AnyKeyNotification(ButtonState.Press);
}

AnyKeyNotification repeated(AnyKey key) {
    return AnyKeyNotification(ButtonState.Repeat);
}

AnyKeyNotification released(AnyKey key) {
    return AnyKeyNotification(ButtonState.Release);
}

auto when(AnyKeyNotification notification) {
    import sbylib.graphics.event : Event, when, finish, then;

    auto event = new Event!KeyButton;
    auto cb = KeyEventWatcher.add((Window, KeyButton button, int, ButtonState state, BitFlags!ModKeyButton mods) {
        if (notification.state == state) event.fire(button);
    });
    when(event.finish).then({ KeyEventWatcher.remove(cb); });
    return event;
}

private class KeyEventWatcher {
static:
    private Array!KeyCallback callbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;
        Window.getCurrentWindow().setKeyCallback!(
            keyCallback,
            (Exception e) {
                import std.conv : ConvException;
                if (cast(ConvException)e) return;
                assert(false, e.toString());
            });
    }

    private KeyCallback add(KeyCallback callback) {
        use();
        callbackList ~= callback;
        return callback;
    }

    private void remove(KeyCallback callback) {
        import std.algorithm : find;
        import std.range : take;

        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    void keyCallback(Window window, KeyButton button, int scanCode, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (cb; callbackList) {
            cb(window, button, scanCode, state, mods);
        }
    }
}
