module sbylib.graphics.glsl.parse.precisiontype;

enum PrecisionType {
    Low,
    Medium,
    High
}

string getCode(PrecisionType p) {
    final switch (p) {
        case PrecisionType.Low:
            return "lowp";
        case PrecisionType.Medium:
            return "mediump";
        case PrecisionType.High:
            return "highp";
    }
}
