module sbylib.graphics.animation.wait;

import sbylib.graphics.animation.animation : IAnimation;

public import std.datetime;
public import sbylib.graphics.event : Event;

class WaitAnimation : IAnimation {

    private Duration duration;

    this(Duration duration) {
        this.duration = duration;
    }

    override Event start() {
        import std.datetime : Clock;
        import sbylib.graphics.event : Frame, when, until;

        auto starttime = Clock.currTime;

        return when(Frame).until(() => Clock.currTime > starttime + duration);
    }
}
