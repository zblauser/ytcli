const std = @import("std");

pub const Error = error{
    YtDlpFailed,
} || std.process.RunError;

pub fn resolveAudioUrl(gpa: std.mem.Allocator, io: std.Io, video_id: []const u8) ![]u8 {
    const result = try std.process.run(gpa, io, .{
        .argv = &.{ "yt-dlp", "-f", "bestaudio", "--no-warnings", "-g", video_id },
    });
    defer gpa.free(result.stderr);
    errdefer gpa.free(result.stdout);

    switch (result.term) {
        .exited => |code| if (code != 0) {
            std.debug.print("yt-dlp exit {d}: {s}\n", .{ code, result.stderr });
            return error.YtDlpFailed;
        },
        else => return error.YtDlpFailed,
    }

    var url = std.mem.trim(u8, result.stdout, " \r\n\t");
    if (std.mem.indexOfScalar(u8, url, '\n')) |nl| url = url[0..nl];

    const owned = try gpa.dupe(u8, url);
    gpa.free(result.stdout);
    return owned;
}
