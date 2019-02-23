module sbylib.graphics.camera.camera;

import sbylib.math;
import sbylib.graphics.util : ImplPos, ImplRot, ImplViewMatrix;

abstract class Camera {

    abstract mat4 projectionMatrix();

    mixin ImplPos;
    mixin ImplRot;
    mixin ImplViewMatrix;

    void capture(Entity)(Entity e) {
        e.viewMatrix = this.viewMatrix;
        e.projectionMatrix = this.projectionMatrix;
        e.render();
    }
}
