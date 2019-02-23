module sbylib.graphics.glsl.parse.sharp;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;

import sbylib.graphics.glsl.parse.statement : ImplGraph;

class Sharp : Statement {
    string type;
    string[] values;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import std.array : empty, front;
        import sbylib.graphics.glsl.parse.functions : convert, expect;

        tokens.expect("#");
        this.type = tokens.convert();
        this.values = [tokens.convert()];

        if (!tokens.empty && tokens.front.str == ":") {
            tokens.expect( ":");
            this.values ~= tokens.convert();
        }
    }

    //static Sharp generateVersionDeclare() {
    //    import sbylib.wrapper.gl.GL;
    //    return new Sharp(format!"#version %d"(GL.getShaderVersion()));
    //}

    override string getCode() {
        import std.format : format;

        if (this.type == "version")
            return format!"#%s %s"(this.type, this.values[0]);
        if (this.type == "extension") 
            return format!"#%s %s : %s"(this.type, this.values[0], this.values[1]);

        assert(false);
    }

    //Space getVertexSpace()
    //    in(this.type == "vertex")
    //{
    //    return convert!(Space, getSpaceName)(this.value);
    //}

    //RequireAttribute getRequireAttribute()
    //    in(this.type == "vertex")
    //{
    //    return new RequireAttribute(format!"require Position in %s as vec4 gl_Position;"(this.value));
    //}
}
