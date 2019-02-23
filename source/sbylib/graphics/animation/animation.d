module sbylib.graphics.animation.animation;

public import std.datetime;
public import sbylib.graphics.animation.interpolation : Interpolate;
public import sbylib.graphics.event : Event;

interface IAnimation {
    Event start();
}

class Animation(T) : IAnimation {
    private T delegate() getValue;
    private void delegate(T) setValue;
    private void delegate(float) updateFunction;
    private Duration _period;

    this(ref T value) {
        this.getValue = () => value;
        this.setValue = (T v) { value = v; };
    }

    Animation to(T arrival) {
        import std.typecons : Nullable, nullable;

        Nullable!T departure;
        updateFunction = (float t) {
            if (departure.isNull) departure = getValue().nullable;
            setValue(departure.get() + (arrival - departure.get()) * t);
        };

        return this;
    }

    Animation interpolate(Interpolate i) {
        const b = updateFunction;
        updateFunction = (float t) => b(i(t));
        return this;
    }

    void period(Duration period) {
        this._period = period;
    }

    override Event start() {
        import std.datetime : Clock;
        import sbylib.graphics.event : when, run, until, Frame;

        auto starttime = Clock.currTime;

        return when(Frame).run({
            auto t = cast(float)(Clock.currTime - starttime).total!("msecs") / _period.total!("msecs");
            updateFunction(t);
        })
        .until(() => Clock.currTime > starttime + _period);
    }
}
