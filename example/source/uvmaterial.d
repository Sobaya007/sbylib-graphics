module uvmaterial;

import sbylib.graphics.material.material; 
class UvMaterial : Material {

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

        void main() {
            fragColor = vec4(uv2, 1, 1);
        }
    });
}
