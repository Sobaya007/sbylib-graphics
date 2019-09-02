module sbylib.graphics.util.cameracontrol;

import sbylib.graphics.camera : Camera;
import sbylib.event;
import sbylib.math;
import sbylib.wrapper.glfw;

class CameraControl {

    EventContext context;
    alias context this;

    private Camera camera;
    private vec3 arrivalPos;
    private quat arrivalRot;

    float speed = 0.03;

    this(Camera camera) {
        this.context = new EventContext;
        this.camera = camera;
        this.arrivalPos = camera.pos;
        this.arrivalRot = quat(0,0,0,1);

        auto window = Window.getCurrentWindow;

        with (context()) {
            vec2 basePoint;
            when(MouseButton.Button1.pressed).then({basePoint = mouse.pos;});
            when(MouseButton.Button1.pressed).then({
                if (window.cursorMode == CursorMode.Normal) {
                    window.cursorMode = CursorMode.Disabled;
                } else {
                    window.cursorMode = CursorMode.Normal;
                }
            });

            alias accel = (vec3 v) { 
                if (KeyButton.LeftShift.isPressed) {
                    this.arrivalPos += v * speed * 2;  
                } else {
                    this.arrivalPos += v * speed; 
                }
            };
            when(KeyButton.KeyA.pressing).then({ accel(-camera.rot.column[0]); });
            when(KeyButton.KeyD.pressing).then({ accel(+camera.rot.column[0]); });
            when(KeyButton.KeyQ.pressing).then({ accel(-camera.rot.column[1]); });
            when(KeyButton.KeyE.pressing).then({ accel(+camera.rot.column[1]); });
            when(KeyButton.KeyW.pressing).then({ accel(-camera.rot.column[2]); });
            when(KeyButton.KeyS.pressing).then({ accel(+camera.rot.column[2]); });
            when((Ctrl + KeyButton.KeyD).pressed).then({ window.shouldClose = true; });

            when(mouse.moved).then({
                if (window.cursorMode == CursorMode.Normal) return;
                auto dif = -(mouse.pos - basePoint) * 0.003;
                auto angle = dif.length.rad;
                auto axis = safeNormalize(arrivalRot.toMatrix3 * vec3(dif.y, dif.x, 0));
                arrivalRot = quat.axisAngle(axis, angle) * arrivalRot;
                auto forward = arrivalRot.baseZ;
                auto side = normalize(cross(vec3(0,1,0), forward));
                auto up = normalize(cross(forward, side));
                arrivalRot = mat3(side, up, forward).toQuaternion;
                basePoint = mouse.pos;
            });

            when(Frame).then({
                camera.pos = mix(camera.pos, arrivalPos, 0.1);
                camera.rot = slerp(camera.rot.toQuaternion, arrivalRot, 0.1).normalize.toMatrix3;
            });
        }
    }
}
