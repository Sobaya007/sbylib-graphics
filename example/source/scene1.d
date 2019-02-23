import sbylib.graphics;
import sbylib.wrapper.glfw;
import app : Scene;
import uvmaterial;
import unrealfloormaterial;

Scene createScene1() {
    class Scene1 : Scene {

        private Entity picture;

        private enum Resolution = [500.pixel, 400.pixel];

        this() {

            this.context = new EventContext;

            static class Floor : Entity {
                mixin ImplPos;
                mixin ImplRot;
                mixin ImplScale;
                mixin ImplWorldMatrix;
                mixin Material!(UnrealFloorMaterial);
                mixin ImplBuilder;
                mixin ImplUniform;
            }

            Floor floor;
            with (Floor.Builder()) {
                geometry = GeometryLibrary().buildPlane()
                    .transform(mat3.axisAngle(vec3(1,0,0), 90.deg));

                tileSize = vec2(0.02);
                depthTest = true;

                floor = build();
                floor.pos.y = -0.12;
            }

            static class Box : Entity {
                mixin ImplPos;
                mixin ImplRot;
                mixin ImplScale;
                mixin ImplWorldMatrix;
                mixin Material!(UvMaterial);
                mixin ImplBuilder;
                mixin ImplUniform;
            }

            Box box;
            with (Box.Builder()) {
                geometry = GeometryLibrary().buildBox();

                depthTest = true;

                box = build();
                box.scale = 0.1;
            }

            Camera camera;
            with (PerspectiveCameraBuilder()) {
                near = 0.01;
                far = 10.0;
                fov = 60.deg;
                aspect = cast(float)Resolution[0] / Resolution[1];
                camera = build();
                camera.pos.z = 1.2;

                vec2 basePoint;
                when(context.bound).run({basePoint = mouse.pos;});

                with (context()) {
                    enum delta = 0.01;
                    when(KeyButton.KeyA.pressing).run({ camera.pos -= camera.rot.column[0] * delta; });
                    when(KeyButton.KeyD.pressing).run({ camera.pos += camera.rot.column[0] * delta; });
                    when(KeyButton.KeyQ.pressing).run({ camera.pos -= camera.rot.column[1] * delta; });
                    when(KeyButton.KeyE.pressing).run({ camera.pos += camera.rot.column[1] * delta; });
                    when(KeyButton.KeyW.pressing).run({ camera.pos -= camera.rot.column[2] * delta; });
                    when(KeyButton.KeyS.pressing).run({ camera.pos += camera.rot.column[2] * delta; });

                    when(mouse.moved).run({
                        if (Window.getCurrentWindow().cursorMode == CursorMode.Normal) return;
                        auto dif = (mouse.pos - basePoint) * 0.003;
                        auto angle = dif.length.rad;
                        auto axis = safeNormalize(camera.rot * vec3(dif.y, dif.x, 0));
                        auto rot = mat3.axisAngle(axis, angle);
                        rot *= camera.rot;
                        auto forward = rot.column[2];
                        auto side = normalize(cross(vec3(0,1,0), forward));
                        auto up = normalize(cross(forward, side));
                        camera.rot = mat3(side, up, forward);
                        basePoint = mouse.pos;
                    });
                }
            }

            Canvas canvas;
            with (CanvasBuilder()) {
                size = Resolution;

                color.enable = true;
                color.clear = Color.Black;

                depth.enable = true;

                canvas = build();
            }

            static class PictureMaterial : Material {

                mixin VertexShaderSource!(q{
                    #version 450
                    in vec4 position;
                    in vec2 uv;
                    out vec2 uv2;
                    uniform mat4 worldMatrix;

                    void main() {
                        gl_Position = worldMatrix * position;
                        uv2 = uv;
                    }
                });

                mixin FragmentShaderSource!(q{
                    #version 450
                    in vec2 uv2;
                    out vec4 fragColor;
                    uniform sampler2D tex;
                    
                    void main() {
                        fragColor = texture2D(tex, uv2);
                    }
                });
            }

            static class Picture : Entity {
                mixin ImplPos;
                mixin ImplRot;
                mixin ImplScale;
                mixin ImplWorldMatrix;
                mixin Material!(PictureMaterial);
                mixin ImplBuilder;
                mixin ImplUniform;
            }

            with (Picture.Builder()) {
                geometry = GeometryLibrary().buildPlane();
                tex = canvas.color.texture;

                auto picture = build();
                picture.size = Resolution;
                when(picture.beforeRender).run({ picture.pos.xy = pos; });

                this.picture = picture;

                auto scale = picture.scale;
                when(context.bound).run({
                    with (AnimationBuilder()) {
                        animate(picture.scale)
                        .to(vec3(1))
                        .interpolate(Interpolate.SmoothInOut)
                        .period(400.msecs);

                        start();
                    }
                });

                when(context.unbound).run({
                    with (AnimationBuilder()) {
                        animate(picture.scale)
                        .to(scale)
                        .interpolate(Interpolate.SmoothInOut)
                        .period(400.msecs);

                        start();
                    }
                });
            }

            when(this.beforeRender).run({
                with (canvas.getContext()) {
                    clear(ClearMode.Color, ClearMode.Depth);
                    camera.capture(floor);
                    camera.capture(box);
                }
            });
        }

        override void renderImpl() {
            picture.render();
        }
    }
    return new Scene1;
}
