module normalmaterial;

import sbylib.graphics.material.material; 
class NormalMaterial : Material {

    mixin VertexShaderSource!(q{
        #version 450
        in vec4 position;
        in vec3 normal;
        out vec3 worldNormal;
        uniform mat4 worldMatrix;
        uniform mat4 viewMatrix;
        uniform mat4 projectionMatrix;

        void main() {
            gl_Position = projectionMatrix * viewMatrix * worldMatrix * position;
            worldNormal = (worldMatrix * vec4(normal,0)).xyz;
        }
    });

    mixin FragmentShaderSource!(q{
        #version 450
        in vec3 worldNormal;
        out vec4 fragColor;

        void main() {
            fragColor = vec4(normalize(worldNormal) * .5 + .5, 1);
        }
    });
}
