const std = @import("std");

pub const Theme = struct {
    accent: []const u8,
    accent_strong: []const u8,
    dim: []const u8,
    ghost: []const u8,
    highlight: []const u8,
    title_bg: []const u8 = "",
    reset: []const u8 = "\x1b[0m",
    bold: []const u8 = "\x1b[1m",
};

pub const Named = struct { name: []const u8, theme: Theme };

pub const red: Theme = .{
    .accent = "\x1b[38;5;196m",
    .accent_strong = "\x1b[1;38;5;196m",
    .dim = "\x1b[38;5;243m",
    .ghost = "\x1b[38;5;238m",
    .highlight = "\x1b[48;5;196m\x1b[38;5;231m",
};

pub const cyan: Theme = .{
    .accent = "\x1b[36m",
    .accent_strong = "\x1b[1;36m",
    .dim = "\x1b[2m",
    .ghost = "\x1b[38;5;240m",
    .highlight = "\x1b[7m",
};

pub const mono: Theme = .{
    .accent = "\x1b[37m",
    .accent_strong = "\x1b[1;37m",
    .dim = "\x1b[2m",
    .ghost = "\x1b[38;5;240m",
    .highlight = "\x1b[7m",
};

pub const dracula: Theme = .{
    .accent = "\x1b[38;5;141m",
    .accent_strong = "\x1b[1;38;5;141m",
    .dim = "\x1b[2m",
    .ghost = "\x1b[38;5;240m",
    .highlight = "\x1b[48;5;141m\x1b[38;5;232m",
};

pub const nord: Theme = .{
    .accent = "\x1b[38;5;110m",
    .accent_strong = "\x1b[1;38;5;110m",
    .dim = "\x1b[2m",
    .ghost = "\x1b[38;5;240m",
    .highlight = "\x1b[48;5;110m\x1b[38;5;232m",
};

pub const gruvbox: Theme = .{
    .accent = "\x1b[38;5;214m",
    .accent_strong = "\x1b[1;38;5;214m",
    .dim = "\x1b[38;5;243m",
    .ghost = "\x1b[38;5;240m",
    .highlight = "\x1b[48;5;214m\x1b[38;5;232m",
};

pub const default: Theme = red;

pub const all = [_]Named{
    .{ .name = "red", .theme = red },
    .{ .name = "cyan", .theme = cyan },
    .{ .name = "mono", .theme = mono },
    .{ .name = "dracula", .theme = dracula },
    .{ .name = "nord", .theme = nord },
    .{ .name = "gruvbox", .theme = gruvbox },
};

pub fn byName(name: []const u8) ?Theme {
    if (indexOf(name)) |i| return all[i].theme;
    if (std.mem.eql(u8, name, "yt") or std.mem.eql(u8, name, "youtube")) return red;
    if (std.mem.eql(u8, name, "default")) return default;
    return null;
}

pub fn indexOf(name: []const u8) ?usize {
    for (all, 0..) |n, i| {
        if (std.mem.eql(u8, n.name, name)) return i;
    }
    return null;
}

pub const names = "red, cyan, mono, dracula, nord, gruvbox";
