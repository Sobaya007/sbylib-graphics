module sbylib.graphics.event.finishevent;

public import sbylib.graphics.event.event : Event;

struct Finish {
    Event event;
}

auto finish(Event event) {
    return Finish(event);
}

Event when(Finish finish) {
    auto event = new Event;
    finish.event.addFinishCallback({
        event.call();
    });
    return event;
}
