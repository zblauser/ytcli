const std = @import("std");
const proc = @import("proc.zig");

pub const Error = proc.Error;

pub fn resolveAudioUrl(gpa: std.mem.Allocator, io: std.Io, video_id: []const u8) ![]u8 {
    const out = try proc.runCapture(gpa, io, &.{ "yt-dlp", "-f", "bestaudio", "--no-warnings", "-g", video_id });
    defer gpa.free(out);

    var url = std.mem.trim(u8, out, " \r\n\t");
    if (std.mem.indexOfScalar(u8, url, '\n')) |nl| url = url[0..nl];

    return gpa.dupe(u8, url);
}
