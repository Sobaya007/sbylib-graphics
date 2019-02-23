module sbylib.graphics.glsl.parse.precision;

public import sbylib.graphics.glsl.parse.statement : Statement;
public import sbylib.graphics.glsl.parse.token : Token;
public import sbylib.graphics.glsl.parse.precisiontype : PrecisionType;

import sbylib.graphics.glsl.parse.precisiontype : precisionGetCode = getCode;

class Precision : Statement {
    PrecisionType precision;
    string type;

    mixin ImplVariable;

    this(ref Token[] tokens) {
        import sbylib.graphics.glsl.parse.functions : expect, convert;
        expect(tokens, "precision");
        this.precision = tokens.convert!(PrecisionType, precisionGetCode);
        this.type = tokens.convert();
        expect(tokens, ";");
    }

    override string getCode() {
        import std.format : format;

        return format!"precision %s %s;"(this.precision.precisionGetCode(), this.type);
    }
}
