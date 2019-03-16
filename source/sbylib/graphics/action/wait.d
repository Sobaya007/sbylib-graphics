module sbylib.graphics.action.wait;

import sbylib.graphics.action.action : IAction, ImplAction;

public import std.datetime;
public import sbylib.graphics.event : VoidEvent;

class WaitAction : IAction {

    private Duration duration;

    mixin ImplAction;

    this(Duration duration) {
        this.duration = duration;
    }

    override void start() {
        import std.datetime : Clock;
        import sbylib.graphics.event : Frame, when, until, finish, run;

        auto starttime = Clock.currTime;

        auto wait = when(Frame).until(() => Clock.currTime > starttime + duration || killed);

        when(wait.finish).run({ notifyFinish(); });
    }
}
