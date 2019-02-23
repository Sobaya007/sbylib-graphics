module sbylib.graphics.animation.animationbuilder;

public import std.datetime;

import sbylib.graphics.animation.animation : IAnimation, Animation;
import sbylib.graphics.animation.wait : WaitAnimation;

class AnimationBuilder {

    static opCall() {
        return new typeof(this);
    }

    private IAnimation[] animationList;

    Animation!T animate(T)(ref T value) {
        auto result = new Animation!T(value);
        animationList ~= cast(IAnimation)result;
        return result;
    }

    WaitAnimation wait(Duration dur) {
        auto result = new WaitAnimation(dur);
        animationList ~= cast(IAnimation)result;
        return result;
    }

    void start() {
        start(0);
    }

    private void start(size_t i) 
        in (i < animationList.length)
    {
        import sbylib.graphics.event : when, finish, run;

        if (i >= animationList.length) return;

        auto event = animationList[i].start();
        if (i+1 < animationList.length) {
            when(event.finish).run({ start(i+1); });
        }
    }
}
