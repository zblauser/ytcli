const std = @import("std");

pub const Error = error{ProcFailed} || std.process.RunError;

pub fn runCapture(gpa: std.mem.Allocator, io: std.Io, argv: []const []const u8) Error![]u8 {
    const result = try std.process.run(gpa, io, .{ .argv = argv });
    defer gpa.free(result.stderr);
    errdefer gpa.free(result.stdout);
    switch (result.term) {
        .exited => |code| if (code != 0) {
            std.debug.print("{s} exit {d}: {s}\n", .{ argv[0], code, result.stderr });
            return error.ProcFailed;
        },
        else => return error.ProcFailed,
    }
    return result.stdout;
}
