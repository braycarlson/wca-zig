const std = @import("std");

const assert = std.debug.assert;

const Steps = struct {
    check: *std.Build.Step,
    ci: *std.Build.Step,
    test_all: *std.Build.Step,
    test_fmt: *std.Build.Step,
    test_unit: *std.Build.Step,
};

const Context = struct {
    builder: *std.Build,
    filters: []const []const u8,
    optimize: std.lang.Optimize,
    steps: Steps,
    target: std.Build.ResolvedTarget,
};

const format_paths = [_][]const u8{ "build.zig", "src", "examples" };

const example_names = [_][]const u8{
    "render_shared",
    "capture_shared",
    "loopback_capture",
    "enumerate_devices",
    "enumerate_sessions",
    "endpoint_volume",
    "device_events",
};

comptime {
    assert(format_paths.len > 0);
    assert(example_names.len > 0);
}

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const filters = builder.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &.{};

    const context = Context{
        .builder = builder,
        .filters = filters,
        .optimize = optimize,
        .steps = .{
            .check = builder.step("check", "Compile every artifact without running it"),
            .ci = builder.step("ci", "Run every check and test"),
            .test_all = builder.step("test", "Run every test suite and the format check"),
            .test_fmt = builder.step("test:fmt", "Check that every source file is formatted"),
            .test_unit = builder.step("test:unit", "Run the unit tests and the tidy check"),
        },
        .target = target,
    };

    const wca = builder.addModule("wca", .{
        .root_source_file = builder.path("src/wca.zig"),
        .target = target,
        .optimize = optimize,
    });

    add_library(context);
    add_examples(context, wca);
    add_unit_tests(context);
    add_format(context);

    builder.getInstallStep().dependOn(context.steps.check);
}

fn add_library(context: Context) void {
    const builder = context.builder;

    const library = builder.addLibrary(.{
        .name = "zig-wca",
        .root_module = create_module(context, "src/wca.zig"),
    });

    builder.installArtifact(library);

    context.steps.check.dependOn(&library.step);
}

fn add_examples(context: Context, wca: *std.Build.Module) void {
    const builder = context.builder;

    for (example_names) |name| {
        const module = create_module(context, builder.fmt("examples/{s}.zig", .{name}));

        module.addImport("wca", wca);

        const exe = builder.addExecutable(.{
            .name = name,
            .root_module = module,
        });

        builder.installArtifact(exe);

        const run = builder.addRunArtifact(exe);

        run.step.dependOn(builder.getInstallStep());
        run.addPassthruArgs();

        const description = builder.fmt("Run the {s} example", .{name});

        builder.step(builder.fmt("run-{s}", .{name}), description).dependOn(&run.step);

        context.steps.check.dependOn(&exe.step);
    }
}

fn add_unit_tests(context: Context) void {
    const builder = context.builder;

    const unit = builder.addTest(.{
        .root_module = create_module(context, "src/unit_tests.zig"),
        .filters = context.filters,
    });

    const run = builder.addRunArtifact(unit);

    run.setCwd(builder.path("."));

    context.steps.test_unit.dependOn(&run.step);
    context.steps.test_all.dependOn(&run.step);
    context.steps.check.dependOn(&unit.step);
    context.steps.ci.dependOn(context.steps.test_unit);
}

fn add_format(context: Context) void {
    const builder = context.builder;

    const format = builder.addFmt(.{
        .paths = builder.pathList(&format_paths),
        .check = true,
    });

    context.steps.test_fmt.dependOn(&format.step);
    context.steps.test_all.dependOn(&format.step);
    context.steps.ci.dependOn(context.steps.test_fmt);
    context.steps.ci.dependOn(context.steps.check);
}

fn create_module(context: Context, root: []const u8) *std.Build.Module {
    const builder = context.builder;

    const module = builder.createModule(.{
        .root_source_file = builder.path(root),
        .target = context.target,
        .optimize = context.optimize,
    });

    return module;
}
