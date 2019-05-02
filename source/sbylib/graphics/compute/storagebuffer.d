module sbylib.graphics.compute.storagebuffer;

import sbylib.graphics.compute.compute : Compute;
import sbylib.wrapper.gl : Buffer, BufferTarget, ProgramInterface, ProgramInterfaceProperty;

class StorageBuffer {

    private Compute compute;
    private string variableName;
    private ubyte[] cpuBuffer;
    private int[string] offset;
    private int[string] stride;
    private Buffer!(ubyte) gpuBuffer;

    this(Compute compute, string variableName) {
        this.compute = compute;
        this.variableName = variableName;
        this.gpuBuffer = new Buffer!(ubyte);
    }

    void send() {
        this.gpuBuffer.sendSubData(this.cpuBuffer, BufferTarget.ShaderStorage);
    }

    void fetch() {
        this.gpuBuffer.getSubData(this.cpuBuffer, BufferTarget.ShaderStorage, 0, this.cpuBuffer.length);
    }

    void bindBase(int binding) {
        this.gpuBuffer.bindBase(BufferTarget.ShaderStorage, binding);
    }

    package void allocate(size_t len) {
        this.gpuBuffer.allocate(len, BufferTarget.ShaderStorage);
        this.cpuBuffer = new ubyte[len];
    }

    protected mixin template GenMember(Type, string name) {
        import std.traits : isArray, ForeachType;
        import std.format : format;

        static if (isArray!(Type)) {
            mixin GenArrayBuffer!(ForeachType!(Type), name);
        } else {
            mixin GenNormal!(Type, name);
        }
    }

    protected mixin template GenNormal(Type, string name) {
        import std.string : replace;

        mixin (q{ ref Type ${name}() { return *cast(Type*)(this.cpuBuffer.ptr + getOffset!(This, "${name}")); }}
            .replace("${name}", name));
    }

    protected mixin template GenArrayBuffer(Type, string name) {
        import std.string : replace;
        import sbylib.graphics.compute.storagebuffer : ArrayBuffer;

        mixin (q{
                private ArrayBuffer!(Type) _${name};

                ArrayBuffer!(Type) ${name}() {
                    if (_${name} is null) 
                        _${name} = new ArrayBuffer!(Type)(this,
                            getOffset!(Type[], "${name}"), getStride!(Type[], "${name}")); 
                    return _${name};
                }}
            .replace("${name}", name));
    }

    protected int getOffset(Type, string name)()
        out (r; r >= 0)
    {
        if (name !in offset) {
            offset[name] = compute.program.getProgramProperty(
                ProgramInterface.BufferVariable, ProgramInterfaceProperty.Offset, getName!(Type, name));
        }
        return offset[name];
    }

    protected int getStride(Type, string name)()
        out (r; r >= 0)
    {
        if (name !in stride) {
            stride[name] = compute.program.getProgramProperty(
                ProgramInterface.BufferVariable, ProgramInterfaceProperty.ArrayStride, getName!(Type, name));
        }
        return stride[name];
    }

    protected string getName(Type, string name)() {
        import std.format : format;
        import std.traits : isArray;

        static if (isArray!(Type)) {
            return format!"%s.%s[0]"(variableName, name);
        } else {
            return format!"%s.%s"(variableName, name);
        }
    }
}

class ArrayBuffer(Type) {
    private StorageBuffer buffer;
    private int offset;
    private const int stride;
    private size_t len;

    this(StorageBuffer buffer, int offset, int stride) {
        this.buffer = buffer;
        this.offset = offset;
        this.stride = stride;
    }

    ref Type opIndex(size_t idx) 
        in (idx < len)
    {
        return *cast(Type*)(buffer.cpuBuffer.ptr + offset + stride * idx);
    }

    size_t length() {
        return len;
    }

    void allocate(size_t len) {
        buffer.allocate(offset + stride * len);
        this.len = len;
    }
}
