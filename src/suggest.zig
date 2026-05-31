const std = @import("std");

pub const Error = error{
    HttpFailed,
    BadResponse,
} || std.mem.Allocator.Error || std.process.RunError;

pub fn fetch(arena: std.mem.Allocator, gpa: std.mem.Allocator, io: std.Io, query: []const u8, max: usize) ![][]const u8 {
    if (query.len == 0) return &.{};

    const escaped = try urlEscape(arena, query);
    const url = try std.fmt.allocPrint(arena,
        "https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q={s}",
        .{escaped},
    );

    const result = try std.process.run(gpa, io, .{ .argv = &.{
        "curl", "-sS", "--max-time", "3", url,
    } });
    defer gpa.free(result.stderr);
    defer gpa.free(result.stdout);
    switch (result.term) {
        .exited => |code| if (code != 0) return error.HttpFailed,
        else => return error.HttpFailed,
    }

    const parsed = std.json.parseFromSlice(std.json.Value, arena, result.stdout, .{}) catch return error.BadResponse;
    if (parsed.value != .array or parsed.value.array.items.len < 2) return error.BadResponse;
    const sugs = parsed.value.array.items[1];
    if (sugs != .array) return error.BadResponse;

    var out: std.ArrayList([]const u8) = .empty;
    for (sugs.array.items) |s| {
        if (out.items.len >= max) break;
        if (s != .string) continue;
        try out.append(arena, try arena.dupe(u8, s.string));
    }
    return out.toOwnedSlice(arena);
}

fn urlEscape(arena: std.mem.Allocator, s: []const u8) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    for (s) |ch| {
        const safe = std.ascii.isAlphanumeric(ch) or ch == '-' or ch == '_' or ch == '.' or ch == '~';
        if (safe) {
            try buf.append(arena, ch);
        } else {
            var hex: [3]u8 = undefined;
            _ = try std.fmt.bufPrint(&hex, "%{X:0>2}", .{ch});
            try buf.appendSlice(arena, &hex);
        }
    }
    return buf.toOwnedSlice(arena);
}
