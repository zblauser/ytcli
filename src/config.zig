const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("sys/stat.h");
    @cInclude("errno.h");
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
    const path_z = arena.dupeZ(u8, file_path) catch return null;
    const f = c.fopen(path_z.ptr, "rb") orelse return null;
    defer _ = c.fclose(f);

    _ = c.fseek(f, 0, c.SEEK_END);
    const size = c.ftell(f);
    if (size <= 0) return null;
    _ = c.fseek(f, 0, c.SEEK_SET);

    const buf = arena.alloc(u8, @intCast(size)) catch return null;
    const n = c.fread(buf.ptr, 1, buf.len, f);
    if (n == 0) return null;

    var it = std.mem.splitScalar(u8, buf[0..n], '\n');
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

    if (readAll(arena, file_path)) |bytes| {
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

    if (std.fs.path.dirname(file_path)) |dir| try makePathZ(arena, dir);
    const path_z = try arena.dupeZ(u8, file_path);
    const f = c.fopen(path_z.ptr, "wb") orelse return error.OpenFailed;
    defer _ = c.fclose(f);
    for (keys.items, vals.items) |k, v| {
        const line = try std.fmt.allocPrint(arena, "{s}={s}\n", .{ k, v });
        if (c.fwrite(line.ptr, 1, line.len, f) != line.len) return error.WriteFailed;
    }
}

fn readAll(arena: std.mem.Allocator, file_path: []const u8) ?[]const u8 {
    const path_z = arena.dupeZ(u8, file_path) catch return null;
    const f = c.fopen(path_z.ptr, "rb") orelse return null;
    defer _ = c.fclose(f);
    _ = c.fseek(f, 0, c.SEEK_END);
    const size = c.ftell(f);
    if (size <= 0) return null;
    _ = c.fseek(f, 0, c.SEEK_SET);
    const buf = arena.alloc(u8, @intCast(size)) catch return null;
    const n = c.fread(buf.ptr, 1, buf.len, f);
    if (n == 0) return null;
    return buf[0..n];
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
