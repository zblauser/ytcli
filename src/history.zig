const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("sys/stat.h");
    @cInclude("errno.h");
    @cInclude("string.h");
});

pub fn path(arena: std.mem.Allocator, env: *std.process.Environ.Map) ![]const u8 {
    if (env.get("XDG_DATA_HOME")) |x| {
        return std.fmt.allocPrintSentinel(arena, "{s}/ytcli/history", .{x}, 0);
    }
    const home = env.get("HOME") orelse return error.NoHome;
    return std.fmt.allocPrintSentinel(arena, "{s}/.local/share/ytcli/history", .{home}, 0);
}

pub fn load(arena: std.mem.Allocator, file_path: []const u8) ![][]const u8 {
    const path_z = try arena.dupeZ(u8, file_path);
    const f = c.fopen(path_z.ptr, "rb") orelse return &.{};
    defer _ = c.fclose(f);

    _ = c.fseek(f, 0, c.SEEK_END);
    const size = c.ftell(f);
    if (size <= 0) return &.{};
    _ = c.fseek(f, 0, c.SEEK_SET);

    const buf = try arena.alloc(u8, @intCast(size));
    const n = c.fread(buf.ptr, 1, buf.len, f);
    if (n == 0) return &.{};
    const bytes = buf[0..n];

    var all: std.ArrayList([]const u8) = .empty;
    var it = std.mem.splitScalar(u8, bytes, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        try all.append(arena, trimmed);
    }

    var seen: std.StringHashMap(void) = .init(arena);
    var out: std.ArrayList([]const u8) = .empty;
    var i = all.items.len;
    while (i > 0) {
        i -= 1;
        const line = all.items[i];
        if (seen.contains(line)) continue;
        try seen.put(line, {});
        try out.append(arena, line);
    }
    return out.toOwnedSlice(arena);
}

pub fn append(arena: std.mem.Allocator, file_path: []const u8, query: []const u8) !void {
    if (std.fs.path.dirname(file_path)) |dir| {
        try makePathZ(arena, dir);
    }
    const path_z = try arena.dupeZ(u8, file_path);
    const f = c.fopen(path_z.ptr, "ab") orelse return error.OpenFailed;
    defer _ = c.fclose(f);
    if (c.fwrite(query.ptr, 1, query.len, f) != query.len) return error.WriteFailed;
    if (c.fwrite("\n", 1, 1, f) != 1) return error.WriteFailed;
}

fn makePathZ(arena: std.mem.Allocator, dir: []const u8) !void {
    var i: usize = 0;
    while (i < dir.len) {
        while (i < dir.len and dir[i] == '/') : (i += 1) {}
        const start = i;
        while (i < dir.len and dir[i] != '/') : (i += 1) {}
        if (i == start) break;
        const partial = try arena.dupeZ(u8, dir[0..i]);
        const r = c.mkdir(partial.ptr, 0o755);
        if (r != 0) {
            const e = std.c._errno().*;
            if (e != c.EEXIST) return error.MkdirFailed;
        }
    }
}

pub fn match(arena: std.mem.Allocator, items: []const []const u8, prefix: []const u8, max: usize) ![][]const u8 {
    var out: std.ArrayList([]const u8) = .empty;
    for (items) |s| {
        if (out.items.len >= max) break;
        if (prefix.len == 0 or std.ascii.startsWithIgnoreCase(s, prefix)) {
            try out.append(arena, s);
        }
    }
    return out.toOwnedSlice(arena);
}
