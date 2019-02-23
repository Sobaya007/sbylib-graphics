module sbylib.graphics.glsl.parse.statement;

public import sbylib.graphics.glsl.parse.variable : Variable;

interface Statement {
    string getCode();

    Variable[] variable();

    protected mixin template ImplVariable() {
        import sbylib.graphics.glsl.parse.variable : Variable;

        Variable[] variable() {
            Variable[] result;

            import std.traits : FieldNameTuple, isArray, isAggregateType, hasMember, ForeachType;

            static if (is(typeof(this) == Variable)) result ~= this;

            static foreach (name; FieldNameTuple!(typeof(this))) {

                static if (isAggregateType!(typeof(mixin(name))) && hasMember!(typeof(mixin(name)), "variable")) {
                    result ~= mixin(name).variable;
                } else static if (isArray!(typeof(mixin(name))) && is(ForeachType!(typeof(mixin(name))) == Variable)) {
                    result ~= mixin(name);
                } else static if (is(typeof(mixin(name)) == Variable)) {
                    result ~= mixin(name);
                }
            }

            return result;
        }
    }
}

mixin template ImplGraph(Members...) {

    string graph(bool[] isEnd) {
        import std.array : join;
        import std.format : format;
        import std.traits : isArray;
        import sbylib.graphics.glsl.parse.functions : indent;

        string[] result;

        result ~= format!"%s|---%s"(indent(isEnd[0..$-1]), typeof(this).stringof);

        static foreach (alias mem; Members) {
            static if (isArray!mem) {
                foreach (a; mem) {
                    result ~= format!"%s|---%s"(indent(isEnd), a);
                }
            } else {
                result ~= format!"%s|---%s"(indent(isEnd), mem);
            }
        }

        return result.join("\n");
    }

}
