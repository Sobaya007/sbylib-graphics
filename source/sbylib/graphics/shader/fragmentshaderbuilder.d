module sbylib.graphics.shader.fragmentshaderbuilder;

public import sbylib.graphics.shader.fragmentshader;

import std.format : format;

class FragmentShaderBuilder(UniformSet, string source) 
    if (is(UniformSet == struct))
{
static:

    FragmentShader build() {
        return new FragmentShader(source);
    }

    private UniformSet uniformSet;

    static foreach (mem; __traits(allMembers, UniformSet)) {

        static if (!is(typeof(mixin("UniformSet."~mem)) == function)) {
            mixin(format!q{
                static %s() {
                    return uniformSet.%s;
                }
            }(mem, mem));

            mixin(format!q{
                static %s(typeof(UniformSet.%s) %s) {
                    return uniformSet.%s = %s;
                }
            }(mem, mem, mem, mem, mem));
        }
    }
}
