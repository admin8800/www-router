const config = @import("config.zig");
const xor_key = @import("xor_key").xor_key;
const max_i32: i32 = 2147483647;

comptime {
    if (config.nodes.len == 0 or config.nodes.len > 9)
        @compileError("config.nodes 数量需在 1..=9");
}

fn xorInPlace(buf: []u8) void {
    for (buf, 0..) |*b, i| {
        b.* ^= xor_key[i % xor_key.len];
    }
}

fn encryptComptime(comptime plain: []const u8) [plain.len]u8 {
    @setEvalBranchQuota(10_000);
    var out: [plain.len]u8 = undefined;
    @memcpy(&out, plain);
    for (&out, 0..) |*b, i| {
        b.* ^= xor_key[i % xor_key.len];
    }
    return out;
}

fn Encrypted(comptime plain: []const u8) type {
    return struct {
        pub const data: [plain.len]u8 = encryptComptime(plain);
    };
}

fn buildNodeEncs() [config.nodes.len][]const u8 {
    var out: [config.nodes.len][]const u8 = undefined;
    inline for (config.nodes, 0..) |node, i| {
        out[i] = &Encrypted(node).data;
    }
    return out;
}

const node_encs = buildNodeEncs();
const enc_probe = Encrypted(config.probe_path).data;
const enc_redirect = Encrypted(config.redirect_path).data;

var out_buf: [512]u8 = undefined;
var scratch: [512]u8 = undefined;
var latency_buf: [8]i32 = undefined;

fn decodeTo(enc: []const u8, dest: []u8) []u8 {
    const n = @min(enc.len, dest.len);
    @memcpy(dest[0..n], enc[0..n]);
    xorInPlace(dest[0..n]);
    return dest[0..n];
}

fn writeSlice(dest: []u8, src: []const u8) usize {
    const n = @min(src.len, dest.len);
    @memcpy(dest[0..n], src[0..n]);
    return n;
}

export fn node_count() u32 {
    return config.nodes.len;
}

export fn timeout_ms() i32 {
    return config.timeout_ms;
}

export fn probe_url(index: u32) i32 {
    if (index >= node_encs.len) return -1;
    const base = decodeTo(node_encs[index], scratch[0..256]);
    const path = decodeTo(&enc_probe, scratch[256..384]);

    var len: usize = 0;
    len += writeSlice(out_buf[len..], base);
    len += writeSlice(out_buf[len..], path);
    return @intCast(len);
}

export fn pick_best(latencies_ptr: [*]const i32, count: u32) i32 {
    if (count == 0 or count > node_encs.len) return -1;

    var best_i: ?u32 = null;
    var best_ms: i32 = max_i32;

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const ms = latencies_ptr[i];
        if (ms < 0) continue;
        if (ms < best_ms) {
            best_ms = ms;
            best_i = i;
        }
    }

    const idx = best_i orelse return -1;
    const base = decodeTo(node_encs[idx], scratch[0..256]);
    const path = decodeTo(&enc_redirect, scratch[256..384]);

    var len: usize = 0;
    len += writeSlice(out_buf[len..], base);
    len += writeSlice(out_buf[len..], path);
    return @intCast(len);
}

export fn out_ptr() [*]u8 {
    return &out_buf;
}

export fn latency_ptr() [*]i32 {
    return &latency_buf;
}

export fn latency_cap() u32 {
    return latency_buf.len;
}
