module sbylib.graphics.geometry.geometrylibrary;

public import sbylib.math;
import sbylib.graphics.geometry.geometry;

struct GeometryLibrary {

    auto buildTriangle() {
        import sbylib.graphics.geometry.geometry2d.triangle : buildGeometry;
        return buildGeometry();
    }

    auto buildPlane(bool strip = true) {
        import sbylib.graphics.geometry.geometry2d.plane : buildGeometry;
        return buildGeometry(strip);
    }

    auto buildBox() {
        import sbylib.graphics.geometry.geometry3d.box : buildGeometry;
        return buildGeometry();
    }

    auto buildIcosahedron(uint level) {
        import sbylib.graphics.geometry.geometry3d.icosahedron : buildGeometry;
        return buildGeometry(level);
    }
}
