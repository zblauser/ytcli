const std = @import("std");

// Single source of truth for the version: the package manifest.
const version = @import("build.zig.zon").version;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // libmpv install prefix. Default /usr/local (Intel Homebrew). Override for
    // arm Homebrew (-Dmpv-prefix=/opt/homebrew); pass empty (-Dmpv-prefix=) on
    // Linux to skip manual paths and let pkg-config resolve libmpv-dev.
    const mpv_prefix = b.option([]const u8, "mpv-prefix", "libmpv install prefix (default /usr/local)") orelse "/usr/local";

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    linkMpv(b, mod, mpv_prefix);

    const options = b.addOptions();
    options.addOption([]const u8, "version", version);
    mod.addOptions("build_options", options);

    const exe = b.addExecutable(.{
        .name = "ytcli",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run ytcli");
    run_step.dependOn(&run_cmd.step);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    linkMpv(b, test_mod, mpv_prefix);
    test_mod.addOptions("build_options", options);

    const unit_tests = b.addTest(.{ .root_module = test_mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn linkMpv(b: *std.Build, mod: *std.Build.Module, prefix: []const u8) void {
    if (prefix.len > 0) {
        mod.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{prefix}) });
        mod.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib", .{prefix}) });
    }
    mod.linkSystemLibrary("mpv", .{});
}
