/// 修改域名后执行: zig build

/// 节点基础地址（含 https://，不要末尾斜杠），1~9 个
pub const nodes = [_][]const u8{
    "https://www.baidu.com",
    "https://www.bing.com",
    "https://www.google.com",
};

/// 测速路径（有 HTTP 响应即可，404 也算连通）
pub const probe_path = "/favicon.ico";

/// 选中后跳转路径
pub const redirect_path = "/";

/// 单节点超时（毫秒）
pub const timeout_ms: i32 = 3000;
