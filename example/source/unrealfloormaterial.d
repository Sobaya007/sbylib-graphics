module unrealfloormaterial;

import sbylib.graphics.material.material;

class UnrealFloorMaterial : Material {

    mixin VertexShaderSource!(q{
        #version 450
        in vec4 position;
        in vec2 uv;
        out vec2 uv2;
        uniform mat4 worldMatrix;
        uniform mat4 viewMatrix;
        uniform mat4 projectionMatrix;

        void main() {
            gl_Position = projectionMatrix * viewMatrix * worldMatrix * position;
            uv2 = uv;
        }
    });

    mixin FragmentShaderSource!(q{
        #version 450
        in vec2 uv2;
        out vec4 fragColor;
        uniform vec2 tileSize;

        void main() {
            vec2 po = mod(uv2 / tileSize, 2);
            int x = po.x < 1 ? 0 : 1;
            int y = po.y < 1 ? 0 : 1;
            if (x + y == 0) {
                fragColor = vec4(vec3(0.1), 1);
            } if (x + y == 1) {
                fragColor = vec4(vec3(0.2), 1);
            } else {
                fragColor = vec4(vec3(0.3), 1);
            }
        }
    });
}
