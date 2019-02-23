module sbylib.graphics.animation.interpolation;

private alias Interpolation = float function(float);

enum Interpolate : Interpolation {
    SmoothInOut = function (float t) => t * t * (3 - 2 * t)
}
