import std.algorithm : each;
import std.conv : to;
import sbylib.math;
import sbylib.graphics;
import sbylib.wrapper.gl;
import sbylib.wrapper.glfw;
import scene0 : createScene0;
import scene1 : createScene1;
import scene2 : createScene2;

void main() {

    Window window;
    with (WindowBuilder()) {
        width = 800.pixel;
        height = 600.pixel;
        title = "po";
        resizable = false;
        contextVersionMajor = 4;
        contextVersionMinor = 5;
        window = buildWindow();
    }

    scope(exit) window.destroy();
    window.makeCurrent();

    when(mouse.moved).then({ window.title = mouse.pos.to!string; });

    when(KeyButton.Escape.pressed)
        .then({window.shouldClose = true;});

    GL.initialize(); // must be called after activating context

    static class ColorMaterial : Material {

        mixin VertexShaderSource!(q{
            #version 450
            in vec4 position;
            uniform mat4 worldMatrix;

            void main() {
                gl_Position = worldMatrix * position;
            }
        });

        mixin FragmentShaderSource!(q{
            #version 450
            uniform vec3 color;
            out vec4 fragColor;
            
            void main() {
                fragColor = vec4(color, 1);
            }
        });
    }

    static class TriangleButton : Entity {
        mixin ImplPos;
        mixin ImplRot;
        mixin ImplScale;
        mixin ImplWorldMatrix;
        mixin Material!(ColorMaterial);
        mixin ImplBuilder;
        mixin ImplUniform;
    }

    TriangleButton[] triangleList;
    with (TriangleButton.Builder()) {
        geometry = GeometryLibrary().buildTriangle().rotate(-90.deg);
        color = vec3(0.8);
        auto triangle = build();
        triangle.pos.x = -0.7;
        triangle.pos.y = -0.8;
        triangleList ~= triangle;
    }

    with (TriangleButton.Builder()) {
        geometry = GeometryLibrary().buildTriangle().rotate(90.deg);
        color = vec3(0.8);
        auto triangle = build();
        triangle.pos.x = +0.7;
        triangle.pos.y = -0.8;
        triangleList ~= triangle;
    }

    triangleList.each!((triangle) {
        when(triangle.beforeRender).then({triangle.pixelSize = [50.pixel, 50.pixel];});
    });

    static class TextMaterial : Material {
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
                fragColor = texture(tex, uv2);
            }
        });
    }

    static class TextBox : Entity {
        mixin ImplPos;
        mixin ImplScale;
        mixin ImplWorldMatrix;
        mixin Material!(TextMaterial);
        mixin ImplUniform;
        mixin ImplBuilder;
    }

    TextBox textBox;
    with (TextBox.Builder()) {
        geometry = GeometryLibrary().buildPlane();
        with (StringTextureBuilder()) {
            font = "./font/consola.ttf";
            text = "0";
            tex = build();
        }
        textBox = build();
        textBox.pixelPos = [0.pixel, (window.height/2 - 50).pixel];
        textBox.pixelSize = [tex.width.pixel, tex.height.pixel];
        textBox.scale *= 0.5;
        textBox.blend = true;
    }

    Scene[] sceneList;
    sceneList ~= createScene0;
    sceneList ~= createScene1;
    sceneList ~= createScene2;

    foreach (i; 0..sceneList.length) {
        sceneList[i].pos.x = i * 2;
    }

    auto idx = 0;
    bool running = false;
    void transit(int dif) {
        if (idx + dif < 0) return;
        if (idx + dif >= sceneList.length) return;
        if (running) return;

        idx += dif;

        with (StringTextureBuilder()) {
            font = "./font/consola.ttf";
            text = idx.to!dstring;
            textBox.tex = build();
        }
        textBox.pixelSize = [textBox.tex.width.pixel, textBox.tex.height.pixel];
        textBox.scale *= 0.5;

        Color[2] colors = dif == -1 ? [Color.White, Color.Gray] : [Color.Gray, Color.White];
        foreach (i; 0..2) {
            with (ActionSequence()) {
                animate(triangleList[i].color)
                .to(colors[i].toVector.rgb)
                .interpolate(Interpolate.SmoothInOut)
                .period(400.msecs);

                wait(400.msecs);

                animate(triangleList[i].color)
                .to(vec3(0.8))
                .interpolate(Interpolate.SmoothInOut)
                .period(200.msecs);

                start();
            }
        }

        foreach (i, scene; sceneList) {
            with (ActionSequence()) {
                const arrivalX = (cast(int)i - cast(int)idx) * 2;
                animate(scene.pos.x)
                .to(arrivalX)
                .interpolate(Interpolate.SmoothInOut)
                .period(1.seconds);

                start();
            }
        }
    }

    void start() {
        if (running) return;
        running = true;
        sceneList[idx].context.bind();
    }

    void stop() {
        if (!running) return;
        running = false;
        sceneList[idx].context.unbind();
    }

    when(KeyButton.Left.pressed).then({ transit(-1); });
    when(KeyButton.Right.pressed).then({ transit(+1); });
    when(MouseButton.Button1.pressed).then({
        if (window.cursorMode == CursorMode.Disabled) {
            window.cursorMode = CursorMode.Normal;
            stop();
        } else {
            window.cursorMode = CursorMode.Disabled;
            start();
        }
    });

    Canvas windowCanvas;
    with (CanvasBuilder()) {
        color.clear = Color.Gray;
        windowCanvas = build(window);
    }

    when(Frame).then({
        with (windowCanvas.getContext()) {
            clear(ClearMode.Color, ClearMode.Depth);

            sceneList.each!(scene => scene.render());
            triangleList.each!(triangle => triangle.render());
            textBox.render();
        }
    });

    while (window.shouldClose == false) {
        FrameEventWatcher.update();
        window.swapBuffers();
        GLFW.pollEvents();
    }
}

abstract class Scene : Renderable {
    vec2 pos = vec2(0);
    EventContext context;
}
