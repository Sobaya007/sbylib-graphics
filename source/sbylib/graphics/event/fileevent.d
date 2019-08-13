module sbylib.graphics.event.fileevent;

public import sbylib.graphics.event.event : VoidEvent, IEvent;

private struct FileModifyNotification { string path; }

auto hasModified(string path) {
    import std : absolutePath, buildNormalizedPath;
    return FileModifyNotification(
        path.absolutePath.buildNormalizedPath);
}

VoidEvent when(FileModifyNotification notification) {
    import std : read, timeLastModified;
    import sbylib.graphics.event.frameevent : Frame, when;
    import sbylib.graphics.event.event : then, until;

    const content = read(notification.path);
    const date = notification.path.timeLastModified;
    auto event = new VoidEvent;
    when(Frame).then({
        if (notification.path.timeLastModified > date) {
            if (read(notification.path) != content) {
                event.fireOnce();
            }
        }
    }).until(() => !event.isAlive);
    return event;
}
