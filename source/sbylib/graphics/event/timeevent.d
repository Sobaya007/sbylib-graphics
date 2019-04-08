module sbylib.graphics.event.timeevent;

public import sbylib.graphics.event.event : VoidEvent;

public import std.datetime;

struct TimeNotification {
    SysTime end;
}

auto later(Duration dur) {
  return TimeNotification(Clock.currTime + dur);
}

VoidEvent when(TimeNotification notification) {
    import sbylib.graphics.event : when, Frame, then, until;

    auto result = new VoidEvent;
    when(Frame).then({
        if (Clock.currTime > notification.end) {
            result.fireOnce();
        }
    }).until(() => result.isAlive is false);
    return result;
}
