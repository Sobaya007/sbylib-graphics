module sbylib.graphics.event.finishevent;

public import sbylib.graphics.event.event : VoidEvent, Event;

private struct FinishNotification(Args...) { Event!(Args) event; }

auto finish(Args...)(Event!(Args) event) {
    return FinishNotification!(Args)(event);
}

VoidEvent when(Args...)(FinishNotification!(Args) finish) {
    auto event = new VoidEvent;
    event.context = null;
    finish.event.addFinishCallback({
        event.fire();
    });
    return event;
}
