const std = @import("std");
const fsutil = @import("fsutil.zig");

const c = @cImport({
    @cInclude("stdio.h");
});

pub fn path(arena: std.mem.Allocator, env: *std.process.Environ.Map) ![]const u8 {
    if (env.get("XDG_CONFIG_HOME")) |x| {
        return std.fmt.allocPrintSentinel(arena, "{s}/ytcli/config", .{x}, 0);
    }
    const home = env.get("HOME") orelse return error.NoHome;
    return std.fmt.allocPrintSentinel(arena, "{s}/.config/ytcli/config", .{home}, 0);
}

pub fn loadTheme(arena: std.mem.Allocator, file_path: []const u8) ?[]const u8 {
    return loadKey(arena, file_path, "theme");
}

pub fn saveTheme(arena: std.mem.Allocator, file_path: []const u8, name: []const u8) void {
    saveKey(arena, file_path, "theme", name) catch {};
}

fn loadKey(arena: std.mem.Allocator, file_path: []const u8, key: []const u8) ?[]const u8 {
    const bytes = fsutil.readFileAlloc(arena, file_path) orelse return null;

    var it = std.mem.splitScalar(u8, bytes, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        const eq = std.mem.indexOfScalar(u8, trimmed, '=') orelse continue;
        if (std.mem.eql(u8, trimmed[0..eq], key)) {
            const val = std.mem.trim(u8, trimmed[eq + 1 ..], " \t\r");
            if (val.len == 0) return null;
            return arena.dupe(u8, val) catch null;
        }
    }
    return null;
}

fn saveKey(arena: std.mem.Allocator, file_path: []const u8, key: []const u8, value: []const u8) !void {
    var keys: std.ArrayList([]const u8) = .empty;
    var vals: std.ArrayList([]const u8) = .empty;

    if (fsutil.readFileAlloc(arena, file_path)) |bytes| {
        var it = std.mem.splitScalar(u8, bytes, '\n');
        while (it.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            const eq = std.mem.indexOfScalar(u8, trimmed, '=') orelse continue;
            const k = trimmed[0..eq];
            if (std.mem.eql(u8, k, key)) continue;
            try keys.append(arena, k);
            try vals.append(arena, std.mem.trim(u8, trimmed[eq + 1 ..], " \t\r"));
        }
    }
    try keys.append(arena, key);
    try vals.append(arena, value);

    if (std.fs.path.dirname(file_path)) |dir| try fsutil.makePathZ(arena, dir);
    const path_z = try arena.dupeZ(u8, file_path);
    const f = c.fopen(path_z.ptr, "wb") orelse return error.OpenFailed;
    defer _ = c.fclose(f);
    for (keys.items, vals.items) |k, v| {
        const line = try std.fmt.allocPrint(arena, "{s}={s}\n", .{ k, v });
        if (c.fwrite(line.ptr, 1, line.len, f) != line.len) return error.WriteFailed;
    }
}

