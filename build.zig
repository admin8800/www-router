const std = @import("std");

pub fn build(b: *std.Build) void {
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    var key: [16]u8 = undefined;
    b.graph.io.random(&key);

    var key_src: [128]u8 = undefined;
    const key_len = blk: {
        var len: usize = 0;
        const prefix = "pub const xor_key = [_]u8{ ";
        @memcpy(key_src[len..][0..prefix.len], prefix);
        len += prefix.len;
        for (key, 0..) |byte, i| {
            if (i != 0) {
                key_src[len] = ',';
                key_src[len + 1] = ' ';
                len += 2;
            }
            _ = std.fmt.bufPrint(key_src[len..][0..4], "0x{x:0>2}", .{byte}) catch unreachable;
            len += 4;
        }
        const suffix = " };\n";
        @memcpy(key_src[len..][0..suffix.len], suffix);
        len += suffix.len;
        break :blk len;
    };

    const wf = b.addWriteFiles();
    const key_file = wf.add("xor_key.zig", key_src[0..key_len]);
    const key_mod = b.createModule(.{
        .root_source_file = key_file,
    });

    const wasm = b.addExecutable(.{
        .name = "selector",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/selector.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .strip = true,
            .imports = &.{
                .{ .name = "xor_key", .module = key_mod },
            },
        }),
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;
    wasm.export_memory = true;
    wasm.initial_memory = 65536;
    wasm.max_memory = 65536;
    wasm.stack_size = 8192;

    b.getInstallStep().dependOn(&b.addInstallArtifact(wasm, .{
        .dest_dir = .{ .override = .{ .custom = "www" } },
    }).step);
    b.getInstallStep().dependOn(&b.addInstallFile(b.path("web/index.html"), "www/index.html").step);
}
