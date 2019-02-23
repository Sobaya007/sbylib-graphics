module sbylib.graphics.glsl.parse.attribute;

enum Attribute {
    In,
    Out,
    Uniform,
    Const,
    Flat,
    ReadOnly,
    WriteOnly
}

string getCode(Attribute attr) {
    final switch(attr) {
    case Attribute.In:
        return "in";
    case Attribute.Out:
        return "out";
    case Attribute.Uniform:
        return "uniform";
    case Attribute.Const:
        return "const";
    case Attribute.Flat:
        return "flat";
    case Attribute.ReadOnly:
        return "readonly";
    case Attribute.WriteOnly:
        return "writeonly";
    }
}
