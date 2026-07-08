const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("errno.h");
    @cInclude("unistd.h");
});

pub fn readFileAlloc(arena: std.mem.Allocator, file_path: []const u8) ?[]u8 {
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

pub fn makePathZ(arena: std.mem.Allocator, dir: []const u8) !void {
    var i: usize = 0;
    while (i < dir.len) {
        while (i < dir.len and dir[i] == '/') : (i += 1) {}
        const start = i;
        while (i < dir.len and dir[i] != '/') : (i += 1) {}
        if (i == start) break;
        const partial = try arena.dupeZ(u8, dir[0..i]);
        const r = std.c.mkdir(partial.ptr, 0o755);
        if (r != 0) {
            const e = std.c._errno().*;
            if (e != c.EEXIST) return error.MkdirFailed;
        }
    }
}

const testing = std.testing;

test "readFileAlloc round-trips contents; null on empty or missing" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const path = try a.dupeZ(u8, "/tmp/ytcli_rfa_XXXXXX");
    const fd = c.mkstemp(path.ptr);
    try testing.expect(fd >= 0);
    defer _ = c.unlink(path.ptr);
    const data = "hello\nworld";
    try testing.expectEqual(@as(isize, data.len), c.write(fd, data.ptr, data.len));
    _ = c.close(fd);

    const got = readFileAlloc(a, path) orelse return error.TestUnexpectedNull;
    try testing.expectEqualStrings("hello\nworld", got);

    const empty = try a.dupeZ(u8, "/tmp/ytcli_rfae_XXXXXX");
    const efd = c.mkstemp(empty.ptr);
    try testing.expect(efd >= 0);
    defer _ = c.unlink(empty.ptr);
    _ = c.close(efd);
    try testing.expect(readFileAlloc(a, empty) == null);

    try testing.expect(readFileAlloc(a, "/tmp/ytcli_definitely_missing_zzz") == null);
}

test "makePathZ creates nested dirs and is idempotent" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const base = try a.dupeZ(u8, "/tmp/ytcli_mp_XXXXXX");
    try testing.expect(c.mkdtemp(base.ptr) != null);

    const mid = try std.fmt.allocPrintSentinel(a, "{s}/a", .{base}, 0);
    const nested = try std.fmt.allocPrintSentinel(a, "{s}/a/b", .{base}, 0);
    const leaf = try std.fmt.allocPrintSentinel(a, "{s}/a/b/f", .{base}, 0);
    defer {
        _ = c.unlink(leaf.ptr);
        _ = c.rmdir(nested.ptr);
        _ = c.rmdir(mid.ptr);
        _ = c.rmdir(base.ptr);
    }

    try makePathZ(a, nested);
    try makePathZ(a, nested); 

    const f = c.fopen(leaf.ptr, "wb") orelse return error.TestUnexpectedNull;
    _ = c.fclose(f);
}
